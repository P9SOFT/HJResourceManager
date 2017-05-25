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

#define     HJResourceRemakerResizeImageIdentifier  @"HJResizeImage"
#define     kSeparateCharactor                      @"_"

@implementation HJResourceRemakerResizeImage

+ (NSDictionary *)parameterFromWidth:(NSInteger)width height:(NSInteger)height
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height contentMode:(NSString *)contentMode
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterContentModeKey:contentMode
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale)
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(NSString *)fileFormat
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale),
             HJResourceRemakerResizeImageParameterFileFormatKey:fileFormat
             };
}

+ (NSDictionary * _Nullable)parameterFromWidth:(NSInteger)width height:(NSInteger)height scale:(CGFloat)scale fileFormat:(NSString *)fileFormat contentMode:(NSString *)contentMode
{
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width),
             HJResourceRemakerResizeImageParameterHeightKey:@(height),
             HJResourceRemakerResizeImageParameterScaleKey:@(scale),
             HJResourceRemakerResizeImageParameterFileFormatKey:fileFormat,
             HJResourceRemakerResizeImageParameterContentModeKey:contentMode
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
    NSString *fileFormat = dict[HJResourceRemakerResizeImageParameterFileFormatKey];
    NSString *contentMode = dict[HJResourceRemakerResizeImageParameterContentModeKey];
    if( widthNumber == nil ) {
        widthNumber = @(0);
    }
    if( heightNumber == nil ) {
        heightNumber = @(0);
    }
    if( scaleNumber == nil ) {
        scaleNumber = @([UIScreen mainScreen].scale);
    }
    if( fileFormat == nil ) {
        fileFormat = HJResourceRemakerResizeImageValueJpeg;
    }
    NSString *subIdentifier = nil;
    if( (contentMode == nil) || ([contentMode isEqualToString:HJResourceRemakerResizeImageValueScaleToFill] == YES) ) {
        subIdentifier = [NSString stringWithFormat:@"%@%@%@%@%@%@%@", widthNumber, kSeparateCharactor, heightNumber, kSeparateCharactor, scaleNumber, kSeparateCharactor, fileFormat];
    } else {
        subIdentifier = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@", widthNumber, kSeparateCharactor, heightNumber, kSeparateCharactor, scaleNumber, kSeparateCharactor, fileFormat, kSeparateCharactor, contentMode];
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
    BOOL            toPNG;
    NSString        *contentMode;
    
    if( (anData.length <= 0) || ([anParameter isKindOfClass:[NSDictionary class]] == NO) ) {
        return nil;
    }
    toPNG = [anParameter[HJResourceRemakerResizeImageParameterFileFormatKey] isEqualToString:HJResourceRemakerResizeImageValuePng];
    resizeSize.width = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterWidthKey] floatValue];
    resizeSize.height = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterHeightKey] floatValue];
    if( (resizeSize.width <= 0.0f) && (resizeSize.height <= 0.0f) ) {
        return anData;
    }
    scale = (CGFloat)[anParameter[HJResourceRemakerResizeImageParameterScaleKey] floatValue];
    if( scale == 0.0 ) {
        scale = [UIScreen mainScreen].scale;
    }
    if( (contentMode = anParameter[HJResourceRemakerResizeImageParameterContentModeKey]) == nil ) {
        contentMode = HJResourceRemakerResizeImageValueScaleToFill;
    }
    if( (sourceImage = [UIImage imageWithData:anData]) == nil ) {
        return nil;
    }
    sourceSize = sourceImage.size;
    if( [contentMode isEqualToString:HJResourceRemakerResizeImageValueAspectFit] == YES ) {
        if( sourceSize.width >= sourceSize.height ) {
            rate = resizeSize.width / sourceSize.width;
            resizeSize.height = (int)(sourceSize.height * rate);
        } else {
            rate = resizeSize.height / sourceSize.height;
            resizeSize.width = (int)(sourceSize.width * rate);
        }
    } else if( [contentMode isEqualToString:HJResourceRemakerResizeImageValueAspectFill] == YES ) {
        if( sourceSize.width >= sourceSize.height ) {
            rate = resizeSize.height / sourceSize.height;
            resizeSize.width = (int)(sourceSize.width * rate);
        } else {
            rate = resizeSize.width / sourceSize.width;
            resizeSize.height = (int)(sourceSize.height * rate);
        }
    } else {
        if( (resizeSize.width > 0.0f) && (resizeSize.height <= 0.0f) ) {
            rate = resizeSize.width / sourceSize.width;
            resizeSize.height = (int)(sourceSize.height * rate);
        } else if( (resizeSize.width <= 0) && (resizeSize.height > 0) ) {
            rate = resizeSize.height / sourceSize.height;
            resizeSize.width = (int)(sourceSize.width * rate);
        }
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
    NSData *data = (toPNG == YES) ? UIImagePNGRepresentation(resizedImage) : UIImageJPEGRepresentation(resizedImage, 1.0f);
    return data;
}

@end
