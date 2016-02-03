//
//  HJResourceCipherGzip.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 10. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJResourceCipherGzip.h"

#define     kMinimumReadBufferSize      (1024*1024)

int32_t g_HJResourceCipherGzip_last_issuedId;

@implementation HJResourceCipherGzip

@dynamic readBufferSize;

- (id)init
{
    if( (self = [super init]) != nil ) {
        _readBufferSize = kMinimumReadBufferSize;
    }
    
    return self;
}

- (NSUInteger)readBufferSize
{
    return _readBufferSize;
}

- (void)setReadBufferSize:(NSUInteger)readBufferSize
{
    if( readBufferSize >= kMinimumReadBufferSize ) {
        _readBufferSize = kMinimumReadBufferSize;
    }
}

- (NSData *)encryptData:(NSData *)anData
{
    NSString *tempFilePath;
    
    if( [anData length] <= 0 ) {
        return nil;
    }
    
    _issuedId = OSAtomicIncrement32(&g_HJResourceCipherGzip_last_issuedId);
    if( (tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"hjr_cipher_module_gzip_temp_%d", _issuedId]]) == nil ) {
        return nil;
    }
    
    if( [self encryptData:anData toFilePath:tempFilePath] == NO ) {
        return nil;
    }
    
    return [NSData dataWithContentsOfFile:tempFilePath];
}

- (NSData *)decryptData:(NSData *)anData
{
    NSString *tempFilePath;
    
    if( [anData length] <= 0 ) {
        return nil;
    }
    
    _issuedId = OSAtomicIncrement32(&g_HJResourceCipherGzip_last_issuedId);
    if( (tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"hjr_cipher_module_gzip_temp_%d", _issuedId]]) == nil ) {
        return nil;
    }
    if( [anData writeToFile:tempFilePath atomically:YES] == NO ) {
        return nil;
    }
    
    return [self decryptDataFromFilePath:tempFilePath];
}

- (BOOL) encryptData:(NSData *)anData toFilePath:(NSString *)path
{
    gzFile gzp;
    
    if( ([anData length] <= 0) || ([path length] <= 0) ) {
        return NO;
    }
    
    if( (gzp = gzopen([path UTF8String], "wb")) == NULL ) {
        return NO;
    }
    if( gzwrite(gzp, [anData bytes], (unsigned int)[anData length]) < 0 ) {
        gzclose(gzp);
        return NO;
    }
    gzclose(gzp);
    
    return YES;
}

- (NSData *)decryptDataFromFilePath:(NSString *)path
{
    int             rbytes;
    unsigned int    length;
    unsigned char   *buffer;
    unsigned char   *plook;
    gzFile          gzp;
    
    if( [path length] <= 0 ) {
        return nil;
    }
    
    if( _readBufferSize < kMinimumReadBufferSize ) {
        _readBufferSize = kMinimumReadBufferSize;
    }
    if( (gzp = gzopen([path UTF8String], "rb")) == NULL ) {
        return nil;
    }
    if( (buffer = (unsigned char *)malloc(_readBufferSize)) == NULL ) {
        gzclose(gzp);
        return nil;
    }
    plook = buffer;
    length = 0;
    while( 1 ) {
        rbytes = gzread(gzp, (voidp)plook, (unsigned int)_readBufferSize);
        if( rbytes <= 0 ) {
            break;
        }
        length += rbytes;
        if( rbytes < _readBufferSize ) {
            break;
        }
        buffer = (unsigned char *)realloc(buffer, length+_readBufferSize);
        plook = buffer + length;
    }
    gzclose(gzp);
    
    return [NSData dataWithBytesNoCopy:(void *)buffer length:length freeWhenDone:YES];
}

@end
