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

- (NSString * _Nullable)identifier;
- (NSString * _Nullable)subIdentifierForParameter:(id _Nullable)anParameter;
- (NSData * _Nullable)remakerData:(NSData * _Nullable)anData withParameter:(id _Nullable)anParameter;

@end
