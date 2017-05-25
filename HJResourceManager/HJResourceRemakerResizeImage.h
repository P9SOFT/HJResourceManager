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
#define     HJResourceRemakerResizeImageParameterContentModeKey @"contentMode"

#define     HJResourceRemakerResizeImageValueJpeg               @"jpeg"
#define     HJResourceRemakerResizeImageValuePng                @"png"
#define     HJResourceRemakerResizeImageValueScaleToFill        @"scaleToFill"
#define     HJResourceRemakerResizeImageValueAspectFit          @"aspectFit"
#define     HJResourceRemakerResizeImageValueAspectFill         @"aspectFill"

@interface HJResourceRemakerResizeImage : NSObject <HJResourceRemakerProtocol>

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height;
+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height contentMode:(NSString * _Nonnull)contentMode;
+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale;
+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(NSString * _Nonnull)fileFormat;
+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(NSString * _Nonnull)fileFormat contentMode:(NSString * _Nonnull)contentMode;

@end
