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
    if( [mimeType length] > 0 ) {
        NSArray *pair = [mimeType componentsSeparatedByString:@"/"];
        if( [pair count] > 0 ) {
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

@end