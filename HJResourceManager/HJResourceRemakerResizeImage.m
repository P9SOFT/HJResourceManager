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
    return [NSDictionary dictionaryWithObjectsAndKeys:@(width), @"width", @(height), @"height", nil];
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
    NSNumber *widthNumber = [dict objectForKey:@"width"];
    NSNumber *heightNumber = [dict objectForKey:@"height"];
    if( (widthNumber == nil) || (heightNumber == nil) ) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"%@%@%@", widthNumber, kSeparateCharactor, heightNumber];
}

- (NSData *)remakerData:(NSData *)anData withParameter:(id)anParameter
{
    NSString        *subIdentifier;
    NSArray         *list;
    CGSize          resizeSize;
    UIImage         *sourceImage;
    CGSize          sourceSize;
    CGFloat         rate;
    UIImage         *resizedImage;
    CGFloat         scale;
    CGColorSpaceRef colorSpace;
    CGContextRef    context;
    CGImageRef      resizedImageRef;
    
    if( ([anData length] <= 0) || ([anParameter isKindOfClass:[NSDictionary class]] == NO) ) {
        return nil;
    }
    if( (subIdentifier = [self subIdentifierForParameter:anParameter]) == nil ) {
        return nil;
    }
    
    list = [subIdentifier componentsSeparatedByString:kSeparateCharactor];
    resizeSize.width = (CGFloat)[[list objectAtIndex:0] integerValue];
    resizeSize.height = (CGFloat)[[list objectAtIndex:1] integerValue];
    scale = 1.0f;
    if( (sourceImage = [UIImage imageWithData:anData scale:scale]) == nil ) {
        return nil;
    }
    sourceSize = sourceImage.size;
        
    if( (resizeSize.width <= 0.0f) && (resizeSize.height <= 0.0f) ) {
        return anData;
    } else if( (resizeSize.width > 0.0f) && (resizeSize.height <= 0.0f) ) {
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
    CGContextScaleCTM(context, scale,  scale);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, resizeSize.width, resizeSize.height), sourceImage.CGImage);
    resizedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    resizedImage = [UIImage imageWithCGImage:resizedImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(resizedImageRef);
    if( resizedImage == nil ) {
        return nil;
    }
    
    NSData *data = ([anParameter objectForKey:@"png"] != nil) ? UIImagePNGRepresentation(resizedImage) : UIImageJPEGRepresentation(resizedImage, 1.0f);
    return data;
}

@end
