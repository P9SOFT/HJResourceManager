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

- (NSData *)encryptData:(NSData *)anData;
- (NSData *)decryptData:(NSData *)anData;
- (BOOL)encryptData:(NSData *)anData toFilePath:(NSString *)path;
- (NSData *)decryptDataFromFilePath:(NSString *)path;

@end