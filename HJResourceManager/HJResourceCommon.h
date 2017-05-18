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
#define     HJResourceQueryKeyImageScale            @"HJResourceQueryImageScale"
#define     HJResourceQueryKeyDataValue             @"HJResourceQueryKeyDataValue"
#define     HJResourceQueryKeyRemakerName           @"HJResourceQueryKeyRemakerName"
#define     HJResourceQueryKeyRemakerParameter      @"HJResourceQueryKeyRemakerParameter"
#define     HJResourceQueryKeyCipherName            @"HJResourceQueryKeyCipherName"
#define     HJResourceQueryKeyExpireTimeInterval    @"HJResourceQueryKeyExpireTimeInterval"
#define     HJResourceQueryKeyBoundarySize          @"HJResourceQueryKeyBoundarySize"

typedef NS_ENUM(NSInteger, HJResourceDataType)
{
    HJResourceDataTypeData,
    HJResourceDataTypeString,
    HJResourceDataTypeImage,
    HJResourceDataTypeSize,
    HJResourceDataTypeFilePath
    
};

@interface HJResourceCommon : NSObject

+ (HJResourceDataType)dataTypeFromMimeType:(NSString * _Nullable)mimeType;

@end
