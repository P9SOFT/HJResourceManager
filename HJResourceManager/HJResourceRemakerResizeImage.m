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
    return @{HJResourceRemakerResizeImageParameterWidthKey:@(width), HJResourceRemakerResizeImageParameterHeightKey:@(height)};
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
    NSNumber *widthNumber = [dict objectForKey:HJResourceRemakerResizeImageParameterWidthKey];
    NSNumber *heightNumber = [dict objectForKey:HJResourceRemakerResizeImageParameterHeightKey];
    NSNumber *scaleNumber = [dict objectForKey:HJResourceRemakerResizeImageParameterScaleKey];
    NSString *fileFormat = [dict objectForKey:HJResourceRemakerResizeImageParameterFileFormatKey];
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
        fileFormat = @"jpeg";
    }
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", widthNumber, kSeparateCharactor, heightNumber, kSeparateCharactor, scaleNumber, kSeparateCharactor, fileFormat];
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
    
    if( ([anData length] <= 0) || ([anParameter isKindOfClass:[NSDictionary class]] == NO) ) {
        return nil;
    }
    toPNG = [[anParameter objectForKey:HJResourceRemakerResizeImageParameterFileFormatKey] isEqualToString:@"png"];
    resizeSize.width = (CGFloat)[[anParameter objectForKey:HJResourceRemakerResizeImageParameterWidthKey] floatValue];
    resizeSize.height = (CGFloat)[[anParameter objectForKey:HJResourceRemakerResizeImageParameterHeightKey] floatValue];
    if( (resizeSize.width <= 0.0f) && (resizeSize.height <= 0.0f) ) {
        return anData;
    }
    scale = (CGFloat)[[anParameter objectForKey:HJResourceRemakerResizeImageParameterScaleKey] floatValue];
    if( scale == 0.0 ) {
        scale = [UIScreen mainScreen].scale;
    }
    if( (sourceImage = [UIImage imageWithData:anData]) == nil ) {
        return nil;
    }
    sourceSize = sourceImage.size;
    if( (resizeSize.width > 0.0f) && (resizeSize.height <= 0.0f) ) {
        rate = resizeSize.width / sourceSize.width;
        resizeSize.height = (int)(sourceSize.height * rate);
    } else if( (resizeSize.width <= 0) && (resizeSize.height > 0) ) {
        rate = resizeSize.height / sourceSize.height;
        resizeSize.width = (int)(sourceSize.width * rate);
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
