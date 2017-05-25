//
//  HJResourceRemakerResizeImage.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 5. 13.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <ImageIO/ImageIO.h>
#import "HJResourceRemakerResizeImage.h"

#define     HJResourceRemakerResizeImageIdentifier              @"HJResizeImage"
#define     kSeparateCharactor                                  @"_"

#define     HJResourceRemakerResizeImageValueJpeg               @"jpeg"
#define     HJResourceRemakerResizeImageValuePng                @"png"
#define     HJResourceRemakerResizeImageValueScaleToFill        @"scaleToFill"
#define     HJResourceRemakerResizeImageValueAspectFit          @"aspectFit"
#define     HJResourceRemakerResizeImageValueAspectFill         @"aspectFill"

@implementation HJResourceRemakerResizeImage

+ (NSDictionary *)parameterFromWidth:(NSInteger)width height:(NSInteger)height
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height contentMode:(HJResourceRemakerResizeImageContentMode)contentMode
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterContentModeKey:@(contentMode)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(HJResourceRemakerResizeImageFileFormat)fileFormat
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale),
             HJResourceRemakerResizeImageParameterFileFormatKey:@(fileFormat)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(HJResourceRemakerResizeImageFileFormat)fileFormat contentMode:(HJResourceRemakerResizeImageContentMode)contentMode
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale),
             HJResourceRemakerResizeImageParameterFileFormatKey:@(fileFormat),
             HJResourceRemakerResizeImageParameterContentModeKey:@(contentMode)
             };
}

- (NSString *)identifier
{
    return HJResourceRemakerResizeImageIdentifier;
}

- (NSString *)subIdentifierForParameter:(id)anParameter
{
    if( [anParameter isKindOfClass:[NSDictionary class]] == NO ) {
        return nil;
    }
    NSDictionary *dict = (NSDictionary *)anParameter;
    NSNumber *widthNumber = dict[HJResourceRemakerResizeImageParameterWidthKey];
    NSNumber *heightNumber = dict[HJResourceRemakerResizeImageParameterHeightKey];
    NSNumber *scaleNumber = dict[HJResourceRemakerResizeImageParameterScaleKey];
    HJResourceRemakerResizeImageFileFormat fileFormat = (HJResourceRemakerResizeImageFileFormat)[dict[HJResourceRemakerResizeImageParameterFileFormatKey] integerValue];
    HJResourceRemakerResizeImageContentMode contentMode = (HJResourceRemakerResizeImageContentMode)[dict[HJResourceRemakerResizeImageParameterContentModeKey] integerValue];
    if( widthNumber == nil ) {
        widthNumber = @(0);
    }
    if( heightNumber == nil ) {
        heightNumber = @(0);
    }
    if( scaleNumber == nil ) {
        scaleNumber = @([UIScreen mainScreen].scale);
    }
    NSString *fileFormatString = HJResourceRemakerResizeImageValueJpeg;
    switch(fileFormat) {
        case HJResourceRemakerResizeImageFileFormatPng :
            fileFormatString = HJResourceRemakerResizeImageValuePng;
            break;
        default :
            break;
    }
    NSString *contentModeString = nil;
    switch(contentMode) {
        case HJResourceRemakerResizeImageContentModeAspectFit :
            contentModeString = HJResourceRemakerResizeImageValueAspectFit;
            break;
        case HJResourceRemakerResizeImageContentModeAspectFill :
            contentModeString = HJResourceRemakerResizeImageValueAspectFill;
            break;
        default :
            break;
    }
    NSString *subIdentifier = nil;
    if( contentModeString == nil ) {
        subIdentifier = [NSString stringWithFormat:@"%@%@%@%@%@%@%@", widthNumber, kSeparateCharactor, heightNumber, kSeparateCharactor, scaleNumber, kSeparateCharactor, fileFormatString];
    } else {
        subIdentifier = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@", widthNumber, kSeparateCharactor, heightNumber, kSeparateCharactor, scaleNumber, kSeparateCharactor, fileFormatString, kSeparateCharactor, contentModeString];
    }
    return subIdentifier;
}

- (NSData *)remakerData:(NSData *)anData withParameter:(id)anParameter
{
    CGSize          resizeSize;
    UIImage         *sourceImage;
    CGSize          sourceSize;
    CGFloat         rate;
    UIImage         *resizedImage;
    CGFloat         scale;
    CGColorSpaceRef colorSpace;
    CGContextRef    context;
    CGImageRef      resizedImageRef;
    HJResourceRemakerResizeImageFileFormat fileFormat;
    HJResourceRemakerResizeImageContentMode contentMode;
    
    if( (anData.length <= 0) || ([anParameter isKindOfClass:[NSDictionary class]] == NO) ) {
        return nil;
    }
    resizeSize.width = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterWidthKey] floatValue];
    resizeSize.height = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterHeightKey] floatValue];
    if( (resizeSize.width <= 0.0f) && (resizeSize.height <= 0.0f) ) {
        return anData;
    }
    scale = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterScaleKey] floatValue];
    if( scale == 0.0 ) {
        scale = [UIScreen mainScreen].scale;
    }
    if( [anParameter[HJResourceRemakerResizeImageParameterFileFormatKey] isKindOfClass:[NSString class]] == YES ) {
        fileFormat = ([anParameter[HJResourceRemakerResizeImageParameterFileFormatKey] isEqualToString:HJResourceRemakerResizeImageValuePng] == YES) ? HJResourceRemakerResizeImageFileFormatPng : HJResourceRemakerResizeImageFileFormatJpeg;
    } else if( [anParameter[HJResourceRemakerResizeImageParameterFileFormatKey] isKindOfClass:[NSNumber class]] == YES ) {
        fileFormat = (HJResourceRemakerResizeImageFileFormat)[anParameter[HJResourceRemakerResizeImageParameterFileFormatKey] integerValue];
    } else {
        fileFormat = HJResourceRemakerResizeImageFileFormatJpeg;
    }
    contentMode = (HJResourceRemakerResizeImageContentMode)[anParameter[HJResourceRemakerResizeImageParameterContentModeKey] integerValue];
    if( (sourceImage = [UIImage imageWithData:anData]) == nil ) {
        return nil;
    }
    sourceSize = sourceImage.size;
    switch(contentMode) {
        case HJResourceRemakerResizeImageContentModeAspectFit :
            if( sourceSize.width >= sourceSize.height ) {
                rate = resizeSize.width / sourceSize.width;
                resizeSize.height = (int)(sourceSize.height * rate);
            } else {
                rate = resizeSize.height / sourceSize.height;
                resizeSize.width = (int)(sourceSize.width * rate);
            }
            break;
        case HJResourceRemakerResizeImageContentModeAspectFill :
            if( sourceSize.width >= sourceSize.height ) {
                rate = resizeSize.height / sourceSize.height;
                resizeSize.width = (int)(sourceSize.width * rate);
            } else {
                rate = resizeSize.width / sourceSize.width;
                resizeSize.height = (int)(sourceSize.height * rate);
            }
            break;
        default :
            if( (resizeSize.width > 0.0f) && (resizeSize.height <= 0.0f) ) {
                rate = resizeSize.width / sourceSize.width;
                resizeSize.height = (int)(sourceSize.height * rate);
            } else if( (resizeSize.width <= 0) && (resizeSize.height > 0) ) {
                rate = resizeSize.height / sourceSize.height;
                resizeSize.width = (int)(sourceSize.width * rate);
            }
            break;
    }
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if( (context = CGBitmapContextCreate(NULL, resizeSize.width*scale, resizeSize.height*scale, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast)) == NULL ) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, resizeSize.width*scale, resizeSize.height*scale), sourceImage.CGImage);
    resizedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    resizedImage = [UIImage imageWithCGImage:resizedImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(resizedImageRef);
    if( resizedImage == nil ) {
        return nil;
    }
    NSData *data = (fileFormat == HJResourceRemakerResizeImageFileFormatPng) ? UIImagePNGRepresentation(resizedImage) : UIImageJPEGRepresentation(resizedImage, 1.0f);
    return data;
}

@end
