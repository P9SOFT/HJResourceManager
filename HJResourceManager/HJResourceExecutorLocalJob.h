//
//  HJResourceExecutorLocalJob.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>

#define		HJResourceExecutorLocalJobName                          @"HJResourceExecutorLocalJobName"

#define		HJResourceExecutorLocalJobParameterKeyStatus                @"HJResourceExecutorLocalJobParameterKeyStatus"
#define		HJResourceExecutorLocalJobParameterKeyOperation             @"HJResourceExecutorLocalJobParameterKeyOperation"
#define		HJResourceExecutorLocalJobParameterKeyDataType              @"HJResourceExecutorLocalJobParameterKeyDataType"
#define		HJResourceExecutorLocalJobParameterKeyMimeType              @"HJResourceExecutorLocalJobParameterKeyMimeType"
#define		HJResourceExecutorLocalJobParameterKeyResourceUrl           @"HJResourceExecutorLocalJobParameterKeyResourceUrl"
#define		HJResourceExecutorLocalJobParameterKeyResourcePath          @"HJResourceExecutorLocalJobParameterKeyResourcePath"
#define		HJResourceExecutorLocalJobParameterKeyRepositoryPath        @"HJResourceExecutorLocalJobParameterKeyRepositoryPath"
#define		HJResourceExecutorLocalJobParameterKeyCipher                @"HJResourceExecutorLocalJobParameterCipher"
#define		HJResourceExecutorLocalJobParameterKeyRemaker               @"HJResourceExecutorLocalJobParameterRemaker"
#define		HJResourceExecutorLocalJobParameterKeyRemakerParameter      @"HJResourceExecutorLocalJobParameterRemakerParameter"
#define     HJResourceExecutorLocalJobParameterKeyExpireTimeInterval    @"HJResourceExecutorLocalJobParameterKeyExpireTimeInterval"
#define     HJResourceExecutorLocalJobParameterKeyBoundarySize          @"HJResourceExecutorLocalJobParameterKeyBoundarySize"
#define		HJResourceExecutorLocalJobParameterKeyDataObject            @"HJResourceExecutorLocalJobParameterKeyDataObject"

typedef enum _HJResourceExecutorLocalJobOperation_
{
    HJResourceExecutorLocalJobOperationLoad,
    HJResourceExecutorLocalJobOperationUpdate,
    HJResourceExecutorLocalJobOperationRemoveByPath,
    HJResourceExecutorLocalJobOperationRemoveByExpireTimeInterval,
    HJResourceExecutorLocalJobOperationRemoveByBoundarySize,
    HJResourceExecutorLocalJobOperationRemoveAll,
    HJResourceExecutorLocalJobOperationAmountSize
	
} HJResourceExecutorLocalJobOperation;

typedef enum _HJResourceExecutorLocalJobStatus_
{
    HJResourceExecutorLocalJobStatusDummy,
    HJResourceExecutorLocalJobStatusLoaded,
    HJResourceExecutorLocalJobStatusUpdated,
    HJResourceExecutorLocalJobStatusRemoved,
    HJResourceExecutorLocalJobStatusCalculated,
    HJResourceExecutorLocalJobStatusFileNotFound,
    HJResourceExecutorLocalJobStatusCanceled,
    HJResourceExecutorLocalJobStatusExpired,
    HJResourceExecutorLocalJobStatusUnknownOperation,
    HJResourceExecutorLocalJobStatusInvalidParameter,
    HJResourceExecutorLocalJobStatusInternalError
	
} HJResourceExecutorLocalJobStatus;


@interface HJResourceExecutorLocalJob : HYExecuter

@end
