//
//  HJResourceRemakerProtocol.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>

@protocol HJResourceCipherProtocol

- (NSData * _Nullable)encryptData:(NSData * _Nullable)anData;
- (NSData * _Nullable)decryptData:(NSData * _Nullable)anData;
- (BOOL)encryptData:(NSData * _Nullable)anData toFilePath:(NSString * _Nullable)path;
- (NSData * _Nullable)decryptDataFromFilePath:(NSString * _Nullable)path;

@end
