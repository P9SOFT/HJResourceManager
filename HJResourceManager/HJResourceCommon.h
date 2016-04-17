//
//  HJResourceData.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>

#define     HJResourceOriginalFileName      @"origin"
#define     HJResourceMimeTypeFileName      @"mimetype"

#define     HJResourceQueryKeyRequestValue          @"HJResourceQueryKeyRequestValue"
#define     HJResourceQueryKeyFirstFetchFrom        @"HJResourceQueryKeyFirstFetchFrom"
#define     HJResourceQueryKeyDataType              @"HJResourceQueryKeyDataType"
#define     HJResourceQueryKeyDataValue             @"HJResourceQueryKeyDataValue"
#define     HJResourceQueryKeyRemakerName           @"HJResourceQueryKeyRemakerName"
#define     HJResourceQueryKeyRemakerParameter      @"HJResourceQueryKeyRemakerParameter"
#define     HJResourceQueryKeyCipherName            @"HJResourceQueryKeyCipherName"
#define     HJResourceQueryKeyExpireTimeInterval    @"HJResourceQueryKeyExpireTimeInterval"
#define     HJResourceQueryKeyBoundarySize          @"HJResourceQueryKeyBoundarySize"

typedef enum _HJResourceDataType_
{
    HJResourceDataTypeData,
    HJResourceDataTypeString,
    HJResourceDataTypeImage,
    HJResourceDataTypeSize,
    HJResourceDataTypeFilePath
    
} HJResourceDataType;

@interface HJResourceCommon : NSObject

+ (HJResourceDataType)dataTypeFromMimeType:(NSString *)mimeType;

@end