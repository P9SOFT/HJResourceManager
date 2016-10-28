//
//  HJResourceManager.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <mach/mach.h>
#import <mach/mach_host.h>
#import <CommonCrypto/CommonHMAC.h>
#import <HJAsyncHttpDeliverer/HJAsyncHttpDeliverer.h>
#import "HJResourceExecutorLocalJob.h"
#import "HJResourceExecutorRemoteJob.h"
#import "HJResourceManager.h"

#define			kMiminumURLStringLength					8
#define			kRemakerPathComponent					@"remaker"
#define         kResourceQueryKey                       @"r"
#define         kCompletionBlockKey                     @"b"
#define         kCutInLineKey                           @"c"

@interface HJResourceManager()
{
    BOOL                        _standby;
    BOOL                        _paused;
    NSUInteger                  _usedMemorySize;
    NSUInteger                  _limitSizeOfMemory;
    NSString                    *_repositoryPath;
    NSLock                      *_lockForResourceDict;
    NSMutableDictionary         *_loadedResourceDict;
    NSMutableArray              *_referenceOrder;
    NSMutableDictionary         *_requestingResourceKeyDict;
    NSMutableDictionary         *_remakingResourceKeyDict;
    NSLock                      *_lockForHashKeyDict;;
    NSMutableDictionary         *_loadedResourceKeyDict;
    NSMutableDictionary         *_loadedHashKeyDict;
    NSLock                      *_lockForSupportDict;
    NSMutableDictionary         *_remakerDict;
    NSMutableDictionary         *_cipherDict;
    HJResourceExecutorLocalJob  *_localJobExecutor;
    HJResourceExecutorRemoteJob *_remoteJobExecutor;
}

- (void)postNotifyWithParamDict:(NSDictionary *)paramDict completion:(HJResourceManagerCompleteBlock)completion;
- (void)postNotifyWithStatus:(HJResourceManagerRequestStatus)status resourceQuery:(NSDictionary *)resourceQuery resource:(id)aResource completion:(HJResourceManagerCompleteBlock)completion;
- (NSString *)requestKeyStringFromResourceQuery:(NSDictionary *)resourceQuery;
- (NSString *)hashKeyStringFromPlainString:(NSString *)plainString;
- (BOOL)isRemoteResource:(NSString *)requestValue;
- (NSUInteger)sizeOfResource:(id)aResource;
- (id)resourceFromMemoryCacheForKey:(NSString *)resourceKey;
- (void)setResourceToMemoryCache:(id)aResource forKey:(NSString *)resourceKey;
- (void)removeResourceFromMemoryCacheForKey:(NSString *)resourceKey;
- (void)balancingWithLimitSizeOfMemory;
- (void)executeCompletionResult:(HYResult *)result withParamDict:(NSMutableDictionary *)paramDict forResourceQuery:(NSDictionary *)resourceQuery;
- (NSMutableDictionary *)localJobHandlerWithResult:(HYResult *)result;
- (NSMutableDictionary *)remoteJobHandlerWithResult:(HYResult *)result;

@end

@implementation HJResourceManager

@synthesize repositoryPath = _repositoryPath;
@synthesize standby = _standby;
@synthesize usedMemorySize = _usedMemorySize;
@dynamic limitSizeOfMemory;
@dynamic timeoutInterval;
@dynamic maximumConnection;

- (NSString *) name
{
    return HJResourceManagerNotification;
}

- (NSString *) brief
{
    return @"resource manager";
}

- (BOOL) didInit
{
    if( (_lockForResourceDict = [[NSLock alloc] init]) == nil ) {
        return NO;
    }
    if( (_loadedResourceDict = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_referenceOrder = [[NSMutableArray alloc] init]) == nil ) {
        return NO;
    }
    if( (_requestingResourceKeyDict = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_remakingResourceKeyDict = [[NSMutableDictionary alloc] init]) == nil) {
        return NO;
    }
    if( (_lockForHashKeyDict = [[NSLock alloc] init]) == nil ) {
        return NO;
    }
    if( (_loadedHashKeyDict = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_lockForSupportDict = [[NSLock alloc] init]) == nil ) {
        return NO;
    }
    if( (_remakerDict = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_cipherDict = [[NSMutableDictionary alloc] init]) == nil ) {
        return NO;
    }
    if( (_localJobExecutor = [[HJResourceExecutorLocalJob alloc] init]) == nil ) {
        return NO;
    }
    if( (_remoteJobExecutor = [[HJResourceExecutorRemoteJob alloc] init]) == nil ) {
        return NO;
    }
    
    return YES;
}

- (void)postNotifyWithParamDict:(NSDictionary *)paramDict completion:(HJResourceManagerCompleteBlock)completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self postNotifyWithParamDict:paramDict];
    });
    
    if( completion == nil ) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(paramDict);
    });
}

- (void)postNotifyWithStatus:(HJResourceManagerRequestStatus)status resourceQuery:(NSDictionary *)resourceQuery resource:(id)aResource completion:(HJResourceManagerCompleteBlock)completion
{
    NSMutableDictionary *paramDict = [NSMutableDictionary new];
    [paramDict setObject:@((NSUInteger)status) forKey:HJResourceManagerParameterKeyRequestStatus];
    if( resourceQuery != nil ) {
        [paramDict setObject:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    }
    if( aResource != nil ) {
        [paramDict setObject:aResource forKey:HJResourceManagerParameterKeyDataObject];
    }
    
    [self postNotifyWithParamDict:[NSDictionary dictionaryWithDictionary:paramDict] completion:completion];
}

- (NSString *)requestKeyStringFromResourceQuery:(NSDictionary *)resourceQuery
{
    return [self hashKeyStringFromPlainString:[resourceQuery objectForKey:HJResourceQueryKeyRequestValue]];
}

- (NSString *)hashKeyStringFromPlainString:(NSString *)plainString
{
    if( [plainString length] == 0 ) {
        return nil;
    }
    
    NSString *hashKeyString;
    
    [_lockForHashKeyDict lock];
    
    if( (hashKeyString = [_loadedHashKeyDict objectForKey:plainString]) == nil ) {
        
        const char *utf8buffer;
        unsigned char pattern[16];
        
        if( (utf8buffer = [plainString UTF8String]) != NULL ) {
            CC_MD5(utf8buffer, (CC_LONG)strlen(utf8buffer), pattern);
            hashKeyString = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                             pattern[0], pattern[1], pattern[2], pattern[3], pattern[4], pattern[5], pattern[6], pattern[7],
                             pattern[8], pattern[9], pattern[10], pattern[11], pattern[12], pattern[13], pattern[14], pattern[15]
                             ];
        } else {
            hashKeyString = nil;
        }
        if( [hashKeyString length] > 0 ) {
            [_loadedHashKeyDict setObject:hashKeyString forKey:plainString];
        }
        
    }
    
    [_lockForHashKeyDict unlock];
    
    return hashKeyString;
}

- (BOOL)isRemoteResource:(NSString *)requestValue
{
    if( [requestValue length] < 8 ) {
        return NO;
    }
    
    if( [requestValue rangeOfString:@"http://"].location == 0 ) {
        return YES;
    }
    if( [requestValue length] >= 9 ) {
        if( [requestValue rangeOfString:@"https://"].location == 0 ) {
            return YES;
        }
    }
    
    return NO;
}

- (NSUInteger)sizeOfResource:(id)aResource
{
    NSUInteger size;
    
    if( [aResource isKindOfClass:[NSString class]] == YES ) {
        size = [aResource lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    } else if( [aResource isKindOfClass:[UIImage class]] == YES ) {
        size = (NSUInteger)(CGImageGetBytesPerRow([aResource CGImage]) * CGImageGetHeight([aResource CGImage]));
    } else if( [aResource isKindOfClass:[NSData class]] == YES ) {
        size = [aResource length];
    } else {
        size = 0;
    }
    
    return size;
}

- (id)resourceFromMemoryCacheForKey:(NSString *)resourceKey
{
    if( [resourceKey length] == 0 ) {
        return nil;
    }
    
    id aResource = nil;
    
    [_lockForResourceDict lock];
    if( (aResource = [_loadedResourceDict objectForKey:resourceKey]) != nil ) {
        NSUInteger count = [_referenceOrder count];
        NSUInteger i;
        for( i=0 ; i<count ; ++i ) {
            if( [[_referenceOrder objectAtIndex:i] isEqualToString:resourceKey] == YES ) {
                if( i != 0 ) {
                    [_referenceOrder removeObjectAtIndex:i];
                    [_referenceOrder insertObject:resourceKey atIndex:0];
                }
                break;
            }
        }
    }
    [_lockForResourceDict unlock];
    
    return aResource;
}

- (void)setResourceToMemoryCache:(id)aResource forKey:(NSString *)resourceKey
{
    if( (aResource == nil) || ([resourceKey length] == 0) ) {
        return;
    }
    
    [_lockForResourceDict lock];
    [_loadedResourceDict setObject:aResource forKey:resourceKey];
    [_referenceOrder addObject:resourceKey];
    _usedMemorySize += [self sizeOfResource:aResource];
    [_lockForResourceDict unlock];
    
    [self balancingWithLimitSizeOfMemory];
}

- (void)removeResourceFromMemoryCacheForKey:(NSString *)resourceKey
{
    if( [resourceKey length] == 0 ) {
        return;
    }
    
    id aResource;
    
    [_lockForResourceDict lock];
    if( (aResource = [_loadedResourceDict objectForKey:resourceKey]) != nil ) {
        NSUInteger size = [self sizeOfResource:aResource];
        if( _usedMemorySize > size ) {
            _usedMemorySize -= size;
        } else {
            _usedMemorySize = 0;
        }
        [_loadedResourceDict removeObjectForKey:resourceKey];
        NSUInteger count = [_referenceOrder count];
        NSUInteger i;
        for( i=0 ; i<count ; ++i ) {
            if( [[_referenceOrder objectAtIndex:i] isEqualToString:resourceKey] == YES ) {
                [_referenceOrder removeObjectAtIndex:i];
                break;
            }
        }
    }
    [_lockForResourceDict unlock];
}

- (void)balancingWithLimitSizeOfMemory
{
    if( _usedMemorySize <= _limitSizeOfMemory ) {
        return;
    }
    
    [_lockForResourceDict lock];
    while( [_referenceOrder count] > 0 ) {
        NSString *resourceKey = [_referenceOrder lastObject];
        NSUInteger size = [self sizeOfResource:[_loadedResourceDict objectForKey:resourceKey]];
        [_loadedResourceDict removeObjectForKey:resourceKey];
        [_referenceOrder removeLastObject];
        if( _usedMemorySize > size ) {
            _usedMemorySize -= size;
        } else {
            _usedMemorySize = 0;
        }
        if( _usedMemorySize <= _limitSizeOfMemory ) {
            break;
        }
    }
    [_lockForResourceDict unlock];
}

- (void)executeCompletionResult:(HYResult *)result withParamDict:(NSMutableDictionary *)paramDict forResourceQuery:(NSDictionary *)resourceQuery
{
    NSString *requestKey = [self requestKeyStringFromResourceQuery:resourceQuery];
    if( [requestKey length] == 0 ) {
        return;
    }
    
    NSArray *requestingWaiters = nil;
    NSArray *remakingWaiters = nil;
    
    [_lockForResourceDict lock];
    if( [_requestingResourceKeyDict objectForKey:requestKey] != nil ) {
        requestingWaiters = [NSArray arrayWithArray:[_requestingResourceKeyDict objectForKey:requestKey]];
        [_requestingResourceKeyDict removeObjectForKey:requestKey];
    }
    if( [_remakingResourceKeyDict objectForKey:requestKey] != nil ) {
        remakingWaiters = [NSArray arrayWithArray:[_remakingResourceKeyDict objectForKey:requestKey]];
        [_remakingResourceKeyDict removeObjectForKey:requestKey];
    }
    [_lockForResourceDict unlock];
    
    for( NSDictionary *waiterDict in remakingWaiters ) {
        NSDictionary *currentResourceQuery = [waiterDict objectForKey:kResourceQueryKey];
        BOOL cutInLine = [[waiterDict objectForKey:kCutInLineKey] boolValue];
        HJResourceManagerCompleteBlock completion = [waiterDict objectForKey:kCompletionBlockKey];
        [self resourceForQuery:currentResourceQuery cutInLine:cutInLine completion:completion];
    }
    
    for( NSDictionary *waiterDict in requestingWaiters ) {
        HJResourceManagerCompleteBlock completion = [waiterDict objectForKey:kCompletionBlockKey];
        if( completion != nil ) {
            completion([NSDictionary dictionaryWithDictionary:paramDict]);
        }
    }
}

- (NSMutableDictionary *)localJobHandlerWithResult:(HYResult *)result
{
    if( result == nil ) {
        return nil;
    }
    
    HJResourceExecutorLocalJobOperation operation = (HJResourceExecutorLocalJobOperation)[[result parameterForKey:HJResourceExecutorLocalJobParameterKeyOperation] integerValue];
    HJResourceExecutorLocalJobStatus status = (HJResourceExecutorLocalJobStatus)[[result parameterForKey:HJResourceExecutorLocalJobParameterKeyStatus] integerValue];
    id dataObject = [result parameterForKey:HJResourceExecutorLocalJobParameterKeyDataObject];
    NSString *resourcePath = [result parameterForKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    NSDictionary *resourceQuery = [result parameterForKey:HJResourceManagerParameterKeyResourceQuery];
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    NSString *requestValue = [resourceQuery objectForKey:HJResourceQueryKeyRequestValue];
    HYQuery *query = nil;
    HJResourceManagerCompleteBlock completion = nil;
    NSMutableDictionary *paramDict = [NSMutableDictionary new];
    if( paramDict == nil ) {
        return nil;
    }
    if( resourceQuery != nil ) {
        [paramDict setObject:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    }
    
    switch( operation ) {
        case HJResourceExecutorLocalJobOperationLoad :
            [self removeResourceFromMemoryCacheForKey:resourceKey];
            switch( status ) {
                case HJResourceExecutorLocalJobStatusFileNotFound :
                    if( ([[result parameterForKey:HJResourceManagerParameterKeyRemoteResourceFlag] boolValue] == YES) && ([result parameterForKey:HJResourceExecutorRemoteJobParameterKeyResourceUrl] == nil) ) {
                        if( (query = [self queryForExecutorName:HJResourceExecutorRemoteJobName]) != nil ) {
                            [query setParametersFromDictionary:[result paramDict]];
                            [query setParameter:@((NSInteger)HJResourceExecutorRemoteJobOperationRequest) forKey:HJResourceExecutorRemoteJobParameterKeyOperation];
                            [query setParameter:requestValue forKey:HJResourceExecutorRemoteJobParameterKeyResourceUrl];
                            [query setParameter:resourcePath forKey:HJResourceExecutorRemoteJobParameterKeyResourcePath];
                            [query setParameter:[resourcePath stringByAppendingPathComponent:HJResourceOriginalFileName] forKey:HJResourceExecutorRemoteJobParameterKeyResourceFilePath];
                            [[Hydra defaultHydra] pushQuery:query];
                            return nil;
                        }
                    }
                    [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoadFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
                    break;
                case HJResourceExecutorLocalJobStatusLoaded :
                    if( dataObject != nil ) {
                        [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoaded) forKey:HJResourceManagerParameterKeyRequestStatus];
                        [paramDict setObject:dataObject forKey:HJResourceManagerParameterKeyDataObject];
                        [self setResourceToMemoryCache:dataObject forKey:resourceKey];
                    } else {
                        [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoadFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
                    }
                    break;
                default :
                    [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoadFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
                    break;
            }
            [self executeCompletionResult:result withParamDict:paramDict forResourceQuery:resourceQuery];
            break;
        case HJResourceExecutorLocalJobOperationUpdate :
            if( status == HJResourceExecutorLocalJobStatusUpdated ) {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusUpdated) forKey:HJResourceManagerParameterKeyRequestStatus];
            } else {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusUpdateFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
            }
            if( (completion = [result parameterForKey:HJResourceManagerParameterKeyCompleteBlock]) != nil ) {
                completion([NSDictionary dictionaryWithDictionary:paramDict]);
            }
            break;
        case HJResourceExecutorLocalJobOperationRemoveByPath :
        case HJResourceExecutorLocalJobOperationRemoveByExpireTimeInterval :
        case HJResourceExecutorLocalJobOperationRemoveByBoundarySize :
        case HJResourceExecutorLocalJobOperationRemoveAll :
            if( status == HJResourceExecutorLocalJobStatusRemoved ) {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusRemoved) forKey:HJResourceManagerParameterKeyRequestStatus];
            } else {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusRemoveFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
            }
            if( (completion = [result parameterForKey:HJResourceManagerParameterKeyCompleteBlock]) != nil ) {
                completion([NSDictionary dictionaryWithDictionary:paramDict]);
            }
            break;
        case HJResourceExecutorLocalJobOperationAmountSize :
            if( (status == HJResourceExecutorLocalJobStatusCalculated) && (dataObject != nil) ) {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusCalculated) forKey:HJResourceManagerParameterKeyRequestStatus];
                [paramDict setObject:dataObject forKey:HJResourceManagerParameterKeyDataObject];
            } else {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusCalculateFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
            }
            if( (completion = [result parameterForKey:HJResourceManagerParameterKeyCompleteBlock]) != nil ) {
                completion([NSDictionary dictionaryWithDictionary:paramDict]);
            }
            break;
        default :
            [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusUnknownError) forKey:HJResourceManagerParameterKeyRequestStatus];
            if( (completion = [result parameterForKey:HJResourceManagerParameterKeyCompleteBlock]) != nil ) {
                completion([NSDictionary dictionaryWithDictionary:paramDict]);
            }
            break;
    }
    
    if( [paramDict count] == 0 ) {
        return nil;
    }
    
    return paramDict;
}

- (NSMutableDictionary *)remoteJobHandlerWithResult:(HYResult *)result
{
    if( result == nil ) {
        return nil;
    }
    
    HJResourceExecutorRemoteJobOperation operation = (HJResourceExecutorRemoteJobOperation)[[result parameterForKey:HJResourceExecutorRemoteJobParameterKeyOperation] integerValue];
    HJResourceExecutorRemoteJobStatus status = (HJResourceExecutorRemoteJobStatus)[[result parameterForKey:HJResourceExecutorRemoteJobParameterKeyStatus] integerValue];
    NSNumber *asyncHttpDelivererIssuedId = [result parameterForKey:HJResourceExecutorRemoteJobParameterKeyAsyncHttpDelivererIssuedId];
    NSDictionary *resourceQuery = [result parameterForKey:HJResourceManagerParameterKeyResourceQuery];
    HYQuery *query = nil;
    NSMutableDictionary *paramDict = [NSMutableDictionary new];
    if( paramDict == nil ) {
        return nil;
    }
    if( resourceQuery != nil ) {
        [paramDict setObject:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    }
    HJResourceManagerCompleteBlock completion = nil;
    
    switch( operation ) {
        case HJResourceExecutorRemoteJobOperationRequest :
            if( asyncHttpDelivererIssuedId != nil ) {
                [paramDict setObject:asyncHttpDelivererIssuedId forKey:HJResourceManagerParameterKeyAsyncHttpDelivererIssuedId];
            }
            if( status == HJResourceExecutorRemoteJobStatusRequested ) {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusDownloadStarted) forKey:HJResourceManagerParameterKeyRequestStatus];
            } else {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoadFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
                [self executeCompletionResult:result withParamDict:paramDict forResourceQuery:resourceQuery];
            }
            break;
        case HJResourceExecutorRemoteJobOperationReceive :
            if( asyncHttpDelivererIssuedId != nil ) {
                [paramDict setObject:asyncHttpDelivererIssuedId forKey:HJResourceManagerParameterKeyAsyncHttpDelivererIssuedId];
            }
            if( (status == HJResourceExecutorRemoteJobStatusReceived) && ((query = [self queryForExecutorName:HJResourceExecutorLocalJobName]) != nil) ) {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusDownloaded) forKey:HJResourceManagerParameterKeyRequestStatus];
                [query setParametersFromDictionary:[result paramDict]];
                [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationLoad) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
                [[Hydra defaultHydra] pushQuery:query];
            } else {
                [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusLoadFailed) forKey:HJResourceManagerParameterKeyRequestStatus];
                [self executeCompletionResult:result withParamDict:paramDict forResourceQuery:resourceQuery];
            }
            break;
        default :
            [paramDict setObject:@((NSInteger)HJResourceManagerRequestStatusUnknownError) forKey:HJResourceManagerParameterKeyRequestStatus];
            if( (completion = [result parameterForKey:HJResourceManagerParameterKeyCompleteBlock]) != nil ) {
                completion([NSDictionary dictionaryWithDictionary:paramDict]);
            }
            break;
    }
    
    if( [paramDict count] == 0 ) {
        return nil;
    }
    
    return paramDict;
}

+ (HJResourceManager *)defaultManager
{
    static dispatch_once_t once;
    static HJResourceManager *sharedInstance;
    dispatch_once(&once, ^{sharedInstance = [[self alloc] init];});
    return sharedInstance;
}

- (BOOL)standbyWithRepositoryPath:(NSString *)repositoryPath localJobWorkerName:(NSString *)localJobWorkerName remoteJobWorkerName:(NSString *)remoteJobWorkerName
{
    if( (self.standby == YES) || ([repositoryPath length] == 0) ) {
        return NO;
    }
    
    BOOL isDirectory;
    
    if( [[NSFileManager defaultManager]	fileExistsAtPath:repositoryPath isDirectory:&isDirectory] == NO ) {
        if( [[NSFileManager defaultManager] createDirectoryAtPath:repositoryPath withIntermediateDirectories:YES attributes:nil error:nil] == NO ) {
            return NO;
        }
    } else {
        if( isDirectory == NO ) {
            return NO;
        }
    }
    
    if( [[repositoryPath substringFromIndex:[repositoryPath length]-1] isEqualToString:@"/"] == YES ) {
        repositoryPath = [repositoryPath substringToIndex:[repositoryPath length]-1];
    }
    
    _repositoryPath = [repositoryPath copy];
    
    [self registExecuter:_localJobExecutor withWorkerName:localJobWorkerName action:@selector(localJobHandlerWithResult:)];
    [self registExecuter:_remoteJobExecutor withWorkerName:remoteJobWorkerName action:@selector(remoteJobHandlerWithResult:)];
    
    _standby = YES;
    
    return _standby;
}

- (void)pauseTransfering
{
    if( self.standby == NO ) {
        return;
    }
    
    [_lockForResourceDict lock];
    if( _paused == YES ) {
        [_lockForResourceDict unlock];
        return;
    }
    _paused = YES;
    [_lockForResourceDict unlock];
    
    [[Hydra defaultHydra] pauseAllQueriesForExecutorName:HJResourceExecutorRemoteJobName atWorkerName:[self employedWorkerNameForExecutorName:HJResourceExecutorRemoteJobName]];
}

- (void)resumeTransfering
{
    if( self.standby == NO ) {
        return;
    }
    
    [_lockForResourceDict lock];
    if( _paused == NO ) {
        [_lockForResourceDict unlock];
        return;
    }
    _paused = NO;
    [_lockForResourceDict unlock];
    
    [[Hydra defaultHydra] resumeAllQueriesForExecutorName:HJResourceExecutorRemoteJobName atWorkerName:[self employedWorkerNameForExecutorName:HJResourceExecutorRemoteJobName]];
}

- (void)cancelTransfering
{
    if( self.standby == NO ) {
        return;
    }
    
    [_lockForResourceDict lock];
    _paused = NO;
    [_lockForResourceDict unlock];
    
    [[Hydra defaultHydra] cancelAllQueriesForExecutorName:HJResourceExecutorRemoteJobName atWorkerName:[self employedWorkerNameForExecutorName:HJResourceExecutorRemoteJobName]];
}

- (id)cipherForName:(NSString *)name
{
    if( (self.standby == NO) || ([name length] == 0) ) {
        return nil;
    }
    
    id cipher;
    
    [_lockForSupportDict lock];
    cipher = [_cipherDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return cipher;
}

- (BOOL)setCipher:(id)cipher forName:(NSString *)name
{
    if( (self.standby == NO) || ([cipher conformsToProtocol:@protocol(HJResourceCipherProtocol)] == NO) || ([name length] == 0) ) {
        return NO;
    }
    
    [_lockForSupportDict lock];
    [_cipherDict setObject:cipher forKey:name];
    [_lockForSupportDict unlock];
    
    return YES;
}

- (void)removeCipherForName:(NSString *)name
{
    if( (self.standby == NO) || ([name length] == 0) ) {
        return;
    }
    
    [_lockForSupportDict lock];
    [_cipherDict removeObjectForKey:name];
    [_lockForSupportDict unlock];
}

- (void)removeAllCiphers
{
    if( self.standby == NO ) {
        return;
    }
    
    [_lockForSupportDict lock];
    [_cipherDict removeAllObjects];
    [_lockForSupportDict unlock];
}

- (NSData *)encryptData:(NSData *)anData forName:(NSString *)name
{
    if( (self.standby == NO) || ([anData length] == 0) || ([name length] == 0) ) {
        return nil;
    }
    
    id cipher;
    
    [_lockForSupportDict lock];
    cipher = [_cipherDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return [cipher encryptData:anData];
}

- (NSData *)decryptData:(NSData *)anData forName:(NSString *)name
{
    if( (self.standby == NO) || ([anData length] == 0) || ([name length] == 0) ) {
        return nil;
    }
    
    id cipher;
    
    [_lockForSupportDict lock];
    cipher = [_cipherDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return [cipher decryptData:anData];
}

- (BOOL)encryptData:(NSData *)anData toFilePath:(NSString *)filePath forName:(NSString *)name
{
    if( (self.standby == NO) || ([anData length] == 0) || ([filePath length] == 0) || ([name length] == 0) ) {
        return NO;
    }
    
    id cipher;
    
    [_lockForSupportDict lock];
    cipher = [_cipherDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return [cipher encryptData:anData toFilePath:filePath];
}

- (NSData *)decryptDataFromFilePath:(NSString *)filePath forName:(NSString *)name
{
    if( (self.standby == NO) || ([filePath length] == 0) || ([name length] == 0) ) {
        return nil;
    }
    
    id cipher;
    
    [_lockForSupportDict lock];
    cipher = [_cipherDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return [cipher decryptDataFromFilePath:filePath];
}

- (id)remakerForName:(NSString *)name
{
    if( (self.standby == NO) || ([name length] == 0) ) {
        return nil;
    }
    
    id remaker;
    
    [_lockForSupportDict lock];
    remaker = [_remakerDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return remaker;
}

- (BOOL)setRemaker:(id)remaker forName:(NSString *)name
{
    if( (self.standby == NO) || ([remaker conformsToProtocol:@protocol(HJResourceRemakerProtocol)] == NO) || ([name length] == 0) ) {
        return NO;
    }
    
    if( ([remaker identifier] == nil) || ([[remaker identifier] isEqualToString:HJResourceOriginalFileName] == YES) || ([[remaker identifier] isEqualToString:HJResourceMimeTypeFileName] == YES) ) {
        return NO;
    }
    
    [_lockForSupportDict lock];
    [_remakerDict setObject:remaker forKey:name];
    [_lockForSupportDict unlock];
    
    return YES;
}

- (void)removeRemakerForName:(NSString *)name
{
    if( (self.standby == NO) || ([name length] == 0) ) {
        return;
    }
    
    [_lockForSupportDict lock];
    [_remakerDict removeObjectForKey:name];
    [_lockForSupportDict unlock];
}

- (void)removeAllRemakers
{
    if( self.standby == NO ) {
        return;
    }
    
    [_lockForSupportDict lock];
    [_remakerDict removeAllObjects];
    [_lockForSupportDict unlock];
}

- (NSData *)remakeData:(NSData *)anData withParameter:(id)anParameter forName:(NSString *)name
{
    if( (self.standby == NO) || ([anData length] == 0) || ([name length] == 0) ) {
        return nil;
    }
    
    id remaker;
    
    [_lockForSupportDict lock];
    remaker = [_remakerDict objectForKey:name];
    [_lockForSupportDict unlock];
    
    return [remaker remakerData:anData withParameter:anParameter];
}

- (void)resourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion
{
    [self resourceForQuery:resourceQuery cutInLine:NO completion:completion];
}

- (void)resourceForQuery:(NSDictionary *)resourceQuery cutInLine:(BOOL)cutInLine completion:(HJResourceManagerCompleteBlock)completion
{
    if( (self.standby == NO) || ([resourceQuery objectForKey:HJResourceQueryKeyRequestValue] == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusLoadFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    
    NSString *requestValue = [resourceQuery objectForKey:HJResourceQueryKeyRequestValue];
    BOOL remoteResourceFalg = [self isRemoteResource:requestValue];
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    NSString *requestKey = [self requestKeyStringFromResourceQuery:resourceQuery];
    NSString *resourcePath = [self resourcePathFromResourceQuery:resourceQuery];
    if( (resourceKey == nil) || (requestKey == nil) || (resourcePath == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusLoadFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    NSNumber *dataTypeNumber = [resourceQuery objectForKey:HJResourceQueryKeyDataType];
    if( dataTypeNumber != nil ) {
        switch( (HJResourceDataType)[dataTypeNumber integerValue] ) {
            case HJResourceDataTypeSize :
                [self postNotifyWithStatus:HJResourceManagerRequestStatusLoaded resourceQuery:resourceQuery resource:[self fileSizeFromReosurceQuery:resourceQuery] completion:completion];
                return;
            case HJResourceDataTypeFilePath :
                [self postNotifyWithStatus:HJResourceManagerRequestStatusLoaded resourceQuery:resourceQuery resource:[self filePathFromReosurceQuery:resourceQuery] completion:completion];
                return;
            default :
                break;
        }
    }
    NSNumber *imageScale = [resourceQuery objectForKey:HJResourceQueryKeyImageScale];
    HJResourceFetchFromType fetchFromType = (HJResourceFetchFromType)[[resourceQuery objectForKey:HJResourceQueryKeyFirstFetchFrom] integerValue];
    
    if( fetchFromType == HJResourceFetchFromTypeMemory ) {
        id aResource = [self resourceFromMemoryCacheForKey:resourceKey];
        if( aResource != nil ) {
            [self postNotifyWithStatus:HJResourceManagerRequestStatusLoaded resourceQuery:resourceQuery resource:aResource completion:completion];
            return;
        }
    }
    
    NSMutableArray *requestingWaiters = nil;
    NSMutableArray *remakingWaiters = nil;
    [_lockForResourceDict lock];
    if( (requestingWaiters = [_requestingResourceKeyDict objectForKey:requestKey]) != nil ) {
        NSDictionary *waiter = (completion != nil) ? @{kResourceQueryKey:resourceQuery,kCutInLineKey:@(cutInLine),kCompletionBlockKey:completion} : @{kResourceQueryKey:resourceQuery,kCutInLineKey:@(cutInLine)};
        NSString *remakerName = [resourceQuery objectForKey:HJResourceQueryKeyRemakerName];
        if( (remakerName != nil) && ([remakerName isEqualToString:HJResourceOriginalFileName] == NO) ) {
            if( (remakingWaiters = [_remakingResourceKeyDict objectForKey:requestKey]) == nil ) {
                if( (remakingWaiters = [[NSMutableArray alloc] init]) == nil ) {
                    [_lockForResourceDict unlock];
                    [self postNotifyWithStatus:HJResourceManagerRequestStatusLoadFailed resourceQuery:resourceQuery resource:nil completion:completion];
                }
                [_remakingResourceKeyDict setObject:remakingWaiters forKey:requestKey];
            }
            [remakingWaiters addObject:waiter];
        } else {
            [requestingWaiters addObject:waiter];
        }
        [_lockForResourceDict unlock];
        return;
    }
    if( (requestingWaiters = [[NSMutableArray alloc] init]) == nil ) {
        [_lockForResourceDict unlock];
        [self postNotifyWithStatus:HJResourceManagerRequestStatusLoadFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    if( completion != nil ) {
        [requestingWaiters addObject:@{kResourceQueryKey:resourceQuery,kCutInLineKey:@(cutInLine),kCompletionBlockKey:completion}];
    } else {
        [requestingWaiters addObject:@{kResourceQueryKey:resourceQuery,kCutInLineKey:@(cutInLine)}];
    }
    [_requestingResourceKeyDict setObject:requestingWaiters forKey:requestKey];
    [_lockForResourceDict unlock];
    
    NSString *cipherName = [resourceQuery objectForKey:HJResourceQueryKeyCipherName];
    id cipher = nil;
    if( [cipherName length] > 0 ) {
        [_lockForSupportDict lock];
        cipher = [_cipherDict objectForKey:cipherName];
        [_lockForSupportDict unlock];
    }
    NSString *remakerName = [resourceQuery objectForKey:HJResourceQueryKeyRemakerName];
    id remaker = nil;
    if( [remakerName length] > 0 ) {
        [_lockForSupportDict lock];
        remaker = [_remakerDict objectForKey:remakerName];
        [_lockForSupportDict unlock];
    }
    id remakerParameter = [resourceQuery objectForKey:HJResourceQueryKeyRemakerParameter];
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusLoadFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationLoad) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:resourcePath forKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    if( remoteResourceFalg == YES ) {
        [query setParameter:requestValue forKey:HJResourceExecutorLocalJobParameterKeyResourceUrl];
    }
    [query setParameter:dataTypeNumber forKey:HJResourceExecutorLocalJobParameterKeyDataType];
    [query setParameter:imageScale forKey:HJResourceExecutorLocalJobParameterKeyImageScale];
    [query setParameter:cipher forKey:HJResourceExecutorLocalJobParameterKeyCipher];
    [query setParameter:remaker forKey:HJResourceExecutorLocalJobParameterKeyRemaker];
    [query setParameter:remakerParameter forKey:HJResourceExecutorLocalJobParameterKeyRemakerParameter];
    [query setParameter:[resourceQuery objectForKey:HJResourceQueryKeyExpireTimeInterval] forKey:HJResourceExecutorLocalJobParameterKeyExpireTimeInterval];
    if( cutInLine == YES ) {
        [query setParameter:@(1) forKey:HJResourceExecutorRemoteJobParameterKeyCutInLine];
    }
    [query setParameter:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    [query setParameter:@(remoteResourceFalg) forKey:HJResourceManagerParameterKeyRemoteResourceFlag];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
}

- (NSDate *)cachedDateOfResourceForQuery:(NSDictionary *)resourceQuery
{
    if( self.standby == NO ) {
        return nil;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    if( resourceKey == nil ) {
        return nil;
    }
    NSString *filePath = [self.repositoryPath stringByAppendingPathComponent:resourceKey];
    if( filePath == nil ) {
        return nil;
    }
    NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    if( attribute == nil ) {
        return nil;
    }
    
    return [attribute objectForKey:NSFileCreationDate];
}

- (BOOL)checkValidationOfResourceWithExpireTimeInterval:(NSTimeInterval)expireTimeInterval forQuery:(NSDictionary *)resourceQuery
{
    if( self.standby == NO ) {
        return NO;
    }
    
    NSDate *createDate = [self cachedDateOfResourceForQuery:resourceQuery];
    if( createDate == nil ) {
        return YES;
    }
    NSDate *expireDate = [createDate dateByAddingTimeInterval:expireTimeInterval];
    if( expireDate == nil ) {
        return NO;
    }
    
    return ([expireDate compare:[NSDate date]] != NSOrderedAscending);
}

- (id)cachedResourceForQuery:(NSDictionary *)resourceQuery
{
    if( self.standby == NO ) {
        return nil;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    if( resourceKey == nil ) {
        return nil;
    }
    id aResource = [self resourceFromMemoryCacheForKey:resourceKey];
    if( aResource == nil ) {
        NSString *filePath = [self filePathFromReosurceQuery:resourceQuery];
        if( filePath == nil ) {
            return nil;
        }
        HJResourceDataType dataType = HJResourceDataTypeData;
        NSNumber *dataTypeNumber = [resourceQuery objectForKey:HJResourceQueryKeyDataType];
        if( dataTypeNumber == nil ) {
            NSString *mimeTypeFilePath = [[self resourcePathFromResourceQuery:resourceQuery] stringByAppendingPathComponent:HJResourceMimeTypeFileName];
            NSString *mimeType = [NSString stringWithContentsOfFile:mimeTypeFilePath encoding:NSUTF8StringEncoding error:nil];
            dataType = [HJResourceCommon dataTypeFromMimeType:mimeType];
        } else {
            dataType = (HJResourceDataType)[dataTypeNumber integerValue];
        }
        NSData *data;
        switch( dataType ) {
            case HJResourceDataTypeData :
                if( (data = [NSData dataWithContentsOfFile:filePath]) != nil ) {
                    aResource = data;
                }
                break;
            case HJResourceDataTypeString :
                if( (data = [NSData dataWithContentsOfFile:filePath]) != nil ) {
                    aResource = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                break;
            case HJResourceDataTypeImage :
                if( (data = [NSData dataWithContentsOfFile:filePath]) != nil ) {
                    aResource = [UIImage imageWithData:data];
                }
                break;
            default :
                aResource = nil;
                break;
        }
        if( aResource != nil ) {
            [self setResourceToMemoryCache:aResource forKey:resourceKey];
        }
    }
    
    return aResource;
}

- (id)pickResourceFromMemoryCacheForQuery:(NSDictionary *)resourceQuery
{
    if( self.standby == NO ) {
        return nil;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    if( resourceKey == nil ) {
        return nil;
    }
    
    return [self resourceFromMemoryCacheForKey:resourceKey];
}

- (void)updateCachedResourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion
{
    if( (self.standby == NO) || ([resourceQuery objectForKey:HJResourceQueryKeyRequestValue] == nil) || ([resourceQuery objectForKey:HJResourceQueryKeyDataValue] == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusUpdateFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    NSString *resourcePath = [self resourcePathFromResourceQuery:resourceQuery];
    if( (resourceKey == nil) || (resourcePath == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusUpdateFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    [self removeResourceFromMemoryCacheForKey:resourceKey];
    NSNumber *dataTypeNumber = [resourceQuery objectForKey:HJResourceQueryKeyDataType];
    if( dataTypeNumber != nil ) {
        if( (HJResourceDataType)[dataTypeNumber integerValue] == HJResourceDataTypeSize ) {
            [self postNotifyWithStatus:HJResourceManagerRequestStatusUpdateFailed resourceQuery:resourceQuery resource:nil completion:completion];
            return;
        }
    }
    id dataValue = [resourceQuery objectForKey:HJResourceQueryKeyDataValue];
    if( dataValue == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusUpdateFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    id cipher = nil;
    NSString *cipherName = [resourceQuery objectForKey:HJResourceQueryKeyCipherName];
    if( [cipherName length] > 0 ) {
        [_lockForSupportDict lock];
        cipher = [_cipherDict objectForKey:cipherName];
        [_lockForSupportDict unlock];
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusUpdateFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationUpdate) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:resourcePath forKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    [query setParameter:dataTypeNumber forKey:HJResourceExecutorLocalJobParameterKeyDataType];
    [query setParameter:dataValue forKey:HJResourceExecutorLocalJobParameterKeyDataObject];
    [query setParameter:cipher forKey:HJResourceExecutorLocalJobParameterKeyCipher];
    [query setParameter:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
}

- (BOOL)unloadResourceForQuery:(NSDictionary *)resourceQuery
{
    if( (self.standby == NO) || ([resourceQuery objectForKey:HJResourceQueryKeyRequestValue] == nil) ) {
        return NO;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    if( resourceKey == nil ) {
        return NO;
    }
    [self removeResourceFromMemoryCacheForKey:resourceKey];
    
    return YES;
}

- (BOOL)unloadAllResources
{
    if( self.standby == NO ) {
        return NO;
    }
    
    [_lockForResourceDict lock];
    _usedMemorySize = 0;
    [_loadedResourceDict removeAllObjects];
    [_referenceOrder removeAllObjects];
    [_lockForResourceDict unlock];
    
    return YES;
}

- (void)removeResourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion
{
    if( (self.standby == NO) || ([resourceQuery objectForKey:HJResourceQueryKeyRequestValue] == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    NSString *resourcePath = [self resourcePathFromResourceQuery:resourceQuery];
    if( (resourceKey == nil) || (resourcePath == nil) ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:resourceQuery resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationRemoveByPath) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:resourcePath forKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    [query setParameter:resourceQuery forKey:HJResourceManagerParameterKeyResourceQuery];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
    
    [self removeResourceFromMemoryCacheForKey:resourceKey];
}

- (void)removeResourcesForElapsedTimeFromNow:(NSTimeInterval)elpasedTime completion:(HJResourceManagerCompleteBlock)completion
{
    if( self.standby == NO ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationRemoveByExpireTimeInterval) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:self.repositoryPath forKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    [query setParameter:[NSNumber numberWithDouble:elpasedTime] forKey:HJResourceExecutorLocalJobParameterKeyExpireTimeInterval];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
    
    [self unloadAllResources];
}

- (void)removeResourcesUnderMaximumBoundarySize:(NSUInteger)maximumBoundarySize completion:(HJResourceManagerCompleteBlock)completion
{
    if( self.standby == NO ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationRemoveByBoundarySize) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:self.repositoryPath forKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    [query setParameter:[NSNumber numberWithUnsignedInteger:maximumBoundarySize] forKey:HJResourceExecutorLocalJobParameterKeyBoundarySize];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
    
    [self unloadAllResources];
}

- (void)removeAllResourcesWithCompletion:(HJResourceManagerCompleteBlock)completion
{
    if( self.standby == NO ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusRemoveFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    [query setParameter:self.repositoryPath forKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationRemoveAll) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
    
    [self unloadAllResources];
}

- (void)amountSizeOfAllResoursesWithCompletion:(HJResourceManagerCompleteBlock)completion
{
    if( self.standby == NO ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusCalculateFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    
    HYQuery *query = [self queryForExecutorName:HJResourceExecutorLocalJobName];
    if( query == nil ) {
        [self postNotifyWithStatus:HJResourceManagerRequestStatusCalculateFailed resourceQuery:nil resource:nil completion:completion];
        return;
    }
    [query setParameter:@((NSInteger)HJResourceExecutorLocalJobOperationAmountSize) forKey:HJResourceExecutorLocalJobParameterKeyOperation];
    [query setParameter:self.repositoryPath forKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    [query setParameter:completion forKey:HJResourceManagerParameterKeyCompleteBlock];
    [[Hydra defaultHydra] pushQuery:query];
}

- (NSString *)resourcePathFromResourceQuery:(NSDictionary *)resourceQuery
{
    NSString *hashKey = [self hashKeyStringFromPlainString:[resourceQuery objectForKey:HJResourceQueryKeyRequestValue]];
    if( hashKey == nil ) {
        return nil;
    }
    
    return [self.repositoryPath stringByAppendingPathComponent:hashKey];
}

- (NSString *)resourceKeyStringFromResourceQuery:(NSDictionary *)resourceQuery
{
    NSString *hashKey = [self hashKeyStringFromPlainString:[resourceQuery objectForKey:HJResourceQueryKeyRequestValue]];
    if( hashKey == nil ) {
        return nil;
    }
    id remaker;
    NSString *remakerName = [resourceQuery objectForKey:HJResourceQueryKeyRemakerName];
    if( [remakerName length] == 0 ) {
        remaker = nil;
    } else {
        [_lockForSupportDict lock];
        remaker = [_remakerDict objectForKey:remakerName];
        [_lockForSupportDict unlock];
    }
    NSString *identifier;
    NSString *subIdentifier;
    if( remaker != nil ) {
        identifier = [remaker identifier];
        subIdentifier = [remaker subIdentifierForParameter:[resourceQuery objectForKey:HJResourceQueryKeyRemakerParameter]];
    } else {
        identifier = HJResourceOriginalFileName;
        subIdentifier = nil;
    }
    if( identifier == nil ) {
        return nil;
    }
    NSString *resourceKey;
    if( [subIdentifier length] > 0 ) {
        resourceKey = [NSString stringWithFormat: @"%@/%@_%@", hashKey, identifier, subIdentifier];
    } else {
        resourceKey = [NSString stringWithFormat: @"%@/%@", hashKey, identifier];
    }
    
    return resourceKey;
}

- (NSString *)filePathFromReosurceQuery:(NSDictionary *)resourceQuery
{
    NSString *resourceKey = [self resourceKeyStringFromResourceQuery:resourceQuery];
    if( [resourceKey length] == 0 ) {
        return nil;
    }
    
    return [self.repositoryPath stringByAppendingPathComponent:resourceKey];
}

- (NSNumber *)fileSizeFromReosurceQuery:(NSDictionary *)resourceQuery
{
    NSString *filePath = [self filePathFromReosurceQuery:resourceQuery];
    if( [filePath length] == 0 ) {
        return nil;
    }
    NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    if( attribute == nil ) {
        return nil;
    }
    
    return [attribute objectForKey:NSFileSize];
}

- (NSUInteger)limitSizeOfMemory
{
    if( self.standby == NO ) {
        return 0;
    }
    
    return _limitSizeOfMemory;
}

- (void)setLimitSizeOfMemory:(NSUInteger)limitSizeOfMemory
{
    if( (self.standby == NO) || (_limitSizeOfMemory == limitSizeOfMemory) ) {
        return;
    }
    
    _limitSizeOfMemory = limitSizeOfMemory;
    [self balancingWithLimitSizeOfMemory];
}

- (NSTimeInterval)timeoutInterval
{
    return _remoteJobExecutor.timeoutInterval;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _remoteJobExecutor.timeoutInterval = timeoutInterval;
}

- (NSInteger)maximumConnection
{
    return _remoteJobExecutor.maximumConnection;
}

- (void)setMaximumConnection:(NSInteger)maximumConnection
{
    _remoteJobExecutor.maximumConnection = maximumConnection;
}

@end
