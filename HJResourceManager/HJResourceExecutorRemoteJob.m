//
//  HJResourceExecutorRemoteJob.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <HJAsyncHttpDeliverer/HJAsyncHttpDeliverer.h>
#import "HJResourceCommon.h"
#import "HJResourceExecutorRemoteJob.h"

@interface HJResourceExecutorRemoteJob () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
{
    NSTimeInterval		_timeoutInterval;
    NSInteger			_maximumConnection;
    NSURLSession        *_session;
    NSMutableDictionary *_taskDict;
}

- (void)setTask:(HJAsyncHttpDeliverer *)deliverer forKey:(NSString *)key;
- (HJAsyncHttpDeliverer *)taskForKey:(NSString *)key;
- (void)removeTaskForKey:(NSString *)key;
- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJResourceExecutorRemoteJobStatus)status;
- (void)requestWithQuery:(id)anQuery;
- (void)receivedWithQuery:(id)anQuery;

@end

@implementation HJResourceExecutorRemoteJob

@synthesize timeoutInterval = _timeoutInterval;
@synthesize maximumConnection = _maximumConnection;

- (instancetype)init
{
    if( (self = [super init]) != nil ) {
        _timeoutInterval = HJResourceExecutorRemoteJobDefaultTimeoutInterval;
        _maximumConnection = HJResourceExecutorRemoteJobDefaultMaximumCountOfConnection;
        if( (_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil]) == nil ) {
            return nil;
        }
        if( (_taskDict = [NSMutableDictionary new]) == nil ) {
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_session invalidateAndCancel];
    _session = nil;
}

- (NSString *)name
{
    return HJResourceExecutorRemoteJobName;
}

- (NSString *)brief
{
    return @"HJResourceManager's executor for downloading data from web server.";
}

- (void)setTask:(HJAsyncHttpDeliverer *)deliverer forKey:(NSString *)key
{
    if( (deliverer == nil) && (key == nil) ) {
        return;
    }
    _taskDict[key] = deliverer;
}

- (HJAsyncHttpDeliverer *)taskForKey:(NSString *)key
{
    if( key == nil ) {
        return nil;
    }
    return _taskDict[key];
}

- (void)removeTaskForKey:(NSString *)key
{
    if( key == nil ) {
        return;
    }
    [_taskDict removeObjectForKey:key];
}

- (BOOL)calledExecutingWithQuery:(id)anQuery
{
    HJResourceExecutorRemoteJobOperation operation = (HJResourceExecutorRemoteJobOperation)[[anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyOperation] integerValue];
    switch( operation ) {
        case HJResourceExecutorRemoteJobOperationRequest :
            [self requestWithQuery: anQuery];
            break;
        case HJResourceExecutorRemoteJobOperationReceive :
            [self receivedWithQuery: anQuery];
            break;
        default :
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusUnknownOperation]];
            break;
    }
    
    return YES;
}

- (BOOL)calledCancelingWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusCanceled]];
    
    return YES;
}

- (id)resultForExpiredQuery:(id)anQuery
{
    return [self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusExpired];
}

- (HYResult *)resultForQuery: (id)anQuery withStatus:(HJResourceExecutorRemoteJobStatus)status
{
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParametersFromDictionary:[anQuery paramDict]];
        [result setParameter:@(status) forKey:HJResourceExecutorRemoteJobParameterKeyStatus];
    }
    
    return result;
}

- (void)requestWithQuery:(id)anQuery
{
    NSString *urlString = [anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyResourceUrl];
    NSString *resourceFilePath = [anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyResourceFilePath];
    NSString *temporaryFilePath;
    if( (temporaryFilePath = [anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyTemporaryFilePath]) == nil ) {
        temporaryFilePath = [NSString stringWithFormat:@"%@%@", resourceFilePath, HJResourceExecutorRemoteJobTemporaryFileNamePostfix];
    }
    BOOL cutInLine = [[anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyCutInLine] boolValue];
    if( (urlString.length == 0) || (resourceFilePath.length == 0) || (temporaryFilePath.length == 0) ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInvalidParameter]];
        return;
    }
    
    HYQuery *closeQuery;
    if( (closeQuery = [HYQuery queryWithWorkerName:[self.employedWorker name] executerName:self.name]) == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInternalError]];
        return;
    }
    [closeQuery setParametersFromDictionary:[anQuery paramDict]];
    [closeQuery setParameter:@(HJResourceExecutorRemoteJobOperationReceive) forKey:HJResourceExecutorRemoteJobParameterKeyOperation];
    [closeQuery setParameter:temporaryFilePath forKey:HJResourceExecutorRemoteJobParameterKeyTemporaryFilePath];
    [closeQuery setParameter:_session forKey:HJAsyncHttpDelivererParameterKeySession];
    
    HJAsyncHttpDeliverer *deliverer;
    if( (deliverer = [[HJAsyncHttpDeliverer alloc] initWithCloseQuery:closeQuery]) == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInternalError]];
        return;
    }
    [deliverer setGetWithUrlString:urlString toFilePath:temporaryFilePath];
    deliverer.timeoutInterval = self.timeoutInterval;
    [deliverer setNotifyStatus:[[anQuery parameterForKey:HJResourceQueryKeyNotifyDeliverer] boolValue]];
    [deliverer activeLimiterName:self.name withCount:self.maximumConnection byOrder:(cutInLine ? HYAsyncTaskActiveOrderToFirst : HYAsyncTaskActiveOrderToLast)];
    [self setTask:deliverer forKey:[@(deliverer.issuedId) stringValue]];
    [self bindAsyncTask:deliverer];
    
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:@(HJResourceExecutorRemoteJobStatusRequested) forKey:HJResourceExecutorRemoteJobParameterKeyStatus];
    [result setParameter:@((NSUInteger)deliverer.issuedId) forKey:HJResourceExecutorRemoteJobParameterKeyAsyncHttpDelivererIssuedId];
    
    [self storeResult:result];
}

- (void)receivedWithQuery:(id)anQuery
{
    NSString *resourceFilePath = [anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyResourceFilePath];
    NSString *temporaryFilePath = [anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyTemporaryFilePath];
    if( (resourceFilePath.length == 0) || (temporaryFilePath.length == 0) ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInvalidParameter]];
        [self removeTaskForKey:[[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] stringValue]];
        return;
    }
    
    if( [[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyFailed] boolValue] == YES ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusNetworkError]];
        [self removeTaskForKey:[[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] stringValue]];
        return;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:resourceFilePath error:nil];
    if( [[NSFileManager defaultManager] moveItemAtPath:temporaryFilePath toPath:resourceFilePath error:nil] == NO ) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryFilePath error: nil];
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInternalError]];
        [self removeTaskForKey:[[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] stringValue]];
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:temporaryFilePath error:nil];
    
    NSURLResponse *response = [anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyResponse];
    NSString *mimeType = (response == nil) ? nil : response.MIMEType;
    NSString *mimeTypeFilePath = [[anQuery parameterForKey:HJResourceExecutorRemoteJobParameterKeyResourcePath] stringByAppendingPathComponent:HJResourceMimeTypeFileName];
    if( (mimeType.length > 0) && (mimeTypeFilePath.length > 0) ) {
        [mimeType writeToFile:mimeTypeFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorRemoteJobStatusInternalError]];
        [self removeTaskForKey:[[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] stringValue]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:@(HJResourceExecutorRemoteJobStatusReceived) forKey:HJResourceExecutorRemoteJobParameterKeyStatus];
    [result setParameter:[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] forKey:HJResourceExecutorRemoteJobParameterKeyAsyncHttpDelivererIssuedId];
    
    [self storeResult: result];
    
    [self removeTaskForKey:[[anQuery parameterForKey:HJAsyncHttpDelivererParameterKeyIssuedId] stringValue]];
}

#pragma mark -
#pragma mark NSURLSessionTaskDelegate, NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    if( completionHandler != nil ) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    HJAsyncHttpDeliverer *deliverer = [self taskForKey:dataTask.taskDescription];
    [deliverer receiveResponse:response];
    if( completionHandler != nil ) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    HJAsyncHttpDeliverer *deliverer = [self taskForKey:dataTask.taskDescription];
    [deliverer receiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    HJAsyncHttpDeliverer *deliverer = [self taskForKey:task.taskDescription];
    [deliverer sendBodyData:bytesSent totalBytesWritten:totalBytesSent totalBytesExpectedToWrite:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    HJAsyncHttpDeliverer *deliverer = [self taskForKey:task.taskDescription];
    if( error != nil ) {
        [deliverer failWithError:error];
    } else {
        [deliverer finishLoading];
    }
}

@end
