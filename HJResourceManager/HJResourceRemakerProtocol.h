//
//  HJResourceRemakerProtocol.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>

@protocol HJResourceRemakerProtocol

- (NSString *)identifier;
- (NSString *)subIdentifierForParameter:(id)anParameter;
- (NSData *)remakerData:(NSData *)anData withParameter:(id)anParameter;

@end