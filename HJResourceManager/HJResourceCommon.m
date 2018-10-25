//
//  HJResourceData.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJResourceCommon.h"

@implementation HJResourceCommon

+ (HJResourceDataType)dataTypeFromMimeType:(NSString *)mimeType
{
    if( mimeType.length > 0 ) {
        NSArray *pair = [mimeType componentsSeparatedByString:@"/"];
        if( pair.count > 0 ) {
            NSString *prefix = [pair[0] lowercaseString];
            if( [prefix isEqualToString:@"text"] == YES ) {
                return HJResourceDataTypeString;
            } else if( [prefix isEqualToString:@"image"] == YES ) {
                return HJResourceDataTypeImage;
            }
        }
    }
    
    return HJResourceDataTypeData;
}

+ (NSDictionary *)queryForDataUrlString:(NSString *)urlString
{
    if( urlString.length == 0 ) {
        return nil;
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeData)};
}

+ (NSDictionary *)queryForStringUrlString:(NSString *)urlString
{
    if( urlString.length == 0 ) {
        return nil;
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeString)};
}

+ (NSDictionary *)queryForImageUrlString:(NSString *)urlString
{
    if( urlString.length == 0 ) {
        return nil;
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeImage)};
}

+ (NSDictionary *)queryForImageUrlString:(NSString *)urlString remakerName:(NSString *)remakerName remakerParameter:(NSDictionary *)remakerParameter
{
    if( (urlString.length == 0) || (remakerName.length == 0) ) {
        return nil;
    }
    if( remakerParameter.count == 0 ) {
        return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeImage), HJResourceQueryKeyRemakerName:remakerName};
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeImage), HJResourceQueryKeyRemakerName:remakerName, HJResourceQueryKeyRemakerParameter:remakerParameter};
}

+ (NSDictionary *)queryForSizeUrlString:(NSString *)urlString
{
    if( urlString.length == 0 ) {
        return nil;
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeSize)};
}

+ (NSDictionary *)queryForFilePathUrlString:(NSString *)urlString
{
    if( urlString.length == 0 ) {
        return nil;
    }
    return @{HJResourceQueryKeyRequestValue:urlString, HJResourceQueryKeyDataType:@(HJResourceDataTypeFilePath)};
}

@end
