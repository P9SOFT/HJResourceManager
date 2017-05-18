//
//  HJResourceExecutorRemoteJob.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>

#define		HJResourceExecutorRemoteJobName                             @"HJResourceExecutorRemoteJobName"

#define		HJResourceExecutorRemoteJobParameterKeyStatus                       @"HJResourceExecutorRemoteJobParameterKeyStatus"
#define		HJResourceExecutorRemoteJobParameterKeyOperation                    @"HJResourceExecutorRemoteJobParameterKeyOperation"
#define		HJResourceExecutorRemoteJobParameterKeyDataType                     @"HJResourceExecutorRemoteJobParameterKeyDataType"
#define		HJResourceExecutorRemoteJobParameterKeyResourceUrl                  @"HJResourceExecutorRemoteJobParameterKeyResourceUrl"
#define		HJResourceExecutorRemoteJobParameterKeyResourcePath                 @"HJResourceExecutorRemoteJobParameterKeyResourcePath"
#define		HJResourceExecutorRemoteJobParameterKeyResourceFilePath             @"HJResourceExecutorRemoteJobParameterKeyResourceFilePath"
#define		HJResourceExecutorRemoteJobParameterKeyTemporaryFilePath            @"HJResourceExecutorRemoteJobParameterKeyTemporaryFilePath"
#define     HJResourceExecutorRemoteJobParameterKeyCutInLine                    @"HJResourceExecutorRemoteJobParameterKeyCutInLine"
#define		HJResourceExecutorRemoteJobParameterKeyAsyncHttpDelivererIssuedId   @"HJResourceExecutorRemoteJobParameterKeyAsyncHttpDeliverereIssuedId"

#define     HJResourceExecutorRemoteJobTemporaryFileNamePostfix         @".downloading"
#define     HJResourceExecutorRemoteJobDefaultTimeoutInterval           8
#define     HJResourceExecutorRemoteJobDefaultMaximumCountOfConnection  8

typedef NS_ENUM(NSInteger, HJResourceExecutorRemoteJobOperation)
{
    HJResourceExecutorRemoteJobOperationRequest,
    HJResourceExecutorRemoteJobOperationReceive,
	
};

typedef NS_ENUM(NSInteger, HJResourceExecutorRemoteJobStatus)
{
    HJResourceExecutorRemoteJobStatusDummy,
    HJResourceExecutorRemoteJobStatusRequested,
    HJResourceExecutorRemoteJobStatusReceived,
    HJResourceExecutorRemoteJobStatusCanceled,
    HJResourceExecutorRemoteJobStatusExpired,
    HJResourceExecutorRemoteJobStatusUnknownOperation,
    HJResourceExecutorRemoteJobStatusInvalidParameter,
    HJResourceExecutorRemoteJobStatusNetworkError,
    HJResourceExecutorRemoteJobStatusInternalError
	
};

@interface HJResourceExecutorRemoteJob : HYExecuter

@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSInteger maximumConnection;

@end
