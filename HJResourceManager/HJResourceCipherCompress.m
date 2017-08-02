//
//  HJResourceCipherCompress.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 10. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJResourceCipherCompress.h"
#import <zlib.h>

@implementation HJResourceCipherCompress

- (NSData *)encryptData:(NSData *)anData
{
    uLong sourceLength;
    Bytef *targetBuffer;
    uLong targetLength;
    
    if( anData.length <= 0 ) {
        return nil;
    }
    
    sourceLength = (uLong)anData.length;
    targetLength = compressBound(sourceLength);
    if( (targetBuffer = (Bytef *)malloc(targetLength)) == NULL ) {
        return nil;
    }
    if( compress((Bytef *)targetBuffer, &targetLength, (const Bytef*)anData.bytes, sourceLength) != Z_OK ) {
        free(targetBuffer);
        return nil;
    }
    if( targetLength <= 0 ) {
        free(targetBuffer);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:(void *)targetBuffer length:targetLength freeWhenDone:YES];
}

- (NSData *)decryptData:(NSData *)anData
{
    uLong sourceLength;
    Bytef *targetBuffer;
    uLong targetLength;
    
    if( anData.length <= 0 ) {
        return nil;
    }
    
    sourceLength = (uLong)anData.length;
    targetLength = sourceLength * 2;
    
    if( (targetBuffer = (Bytef *)malloc(targetLength)) == NULL ) {
        return nil;
    }
    if( uncompress((Bytef *)targetBuffer, &targetLength, (const Bytef*)anData.bytes, sourceLength) != Z_OK ) {
        free(targetBuffer);
        return nil;
    }
    if( targetLength <= 0 ) {
        free(targetBuffer);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:(void *)targetBuffer length:targetLength freeWhenDone:YES];
}

- (BOOL)encryptData:(NSData *)anData toFilePath:(NSString *)path
{
    NSData *encryptedData;
    
    if( (anData.length <= 0) || (path.length <= 0) ) {
        return NO;
    }
    
    if( (encryptedData = [self encryptData:anData]) == nil ) {
        return NO;
    }
    
    return [encryptedData writeToFile:path atomically:YES];
}

- (NSData *)decryptDataFromFilePath:(NSString *)path
{
    if( path.length <= 0 ) {
        return nil;
    }
    
    return [self decryptData:[NSData dataWithContentsOfFile:path]];
}

@end
