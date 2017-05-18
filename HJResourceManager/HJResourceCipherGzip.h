//
//  HJResourceCipherGzip.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 10. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import <zlib.h>
#import <HJResourceManager/HJResourceCipherProtocol.h>

@interface HJResourceCipherGzip : NSObject <HJResourceCipherProtocol>

@property (nonatomic, assign) NSUInteger readBufferSize;

@end
