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

@interface HJResourceRemakerResizeImage : NSObject <HJResourceRemakerProtocol>

+ (NSArray *)parameterFromWidth:(NSInteger)width height:(NSInteger)height;

@end
