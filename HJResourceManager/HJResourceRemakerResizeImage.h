//
//  HJResourceRemakerResizeImage.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 5. 13.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <HJResourceManager/HJResourceRemakerProtocol.h>

#define     HJResourceRemakerResizeImageParameterWidthKey       @"width"
#define     HJResourceRemakerResizeImageParameterHeightKey      @"height"
#define     HJResourceRemakerResizeImageParameterScaleKey       @"scale"
#define     HJResourceRemakerResizeImageParameterFileFormatKey  @"fileFormat"

@interface HJResourceRemakerResizeImage : NSObject <HJResourceRemakerProtocol>

+ (NSDictionary *)parameterFromWidth:(NSInteger)width height:(NSInteger)height;

@end
