//
//  HJResourceCipherBase64.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 10. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJResourceCipherBase64.h"

static char g_base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static char g_base64DecodingTable[128] = {
    0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x3f,
    0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,
    0x3c,0x3d,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,
    0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,
    0x0f,0x10,0x11,0x12,0x13,0x14,0x15,0x16,
    0x17,0x18,0x19,0x00,0x00,0x00,0x00,0x00,
    0x00,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,0x20,
    0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,
    0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,0x30,
    0x31,0x32,0x33,0x00,0x00,0x00,0x00,0x00
};

@implementation HJResourceCipherBase64

- (NSData *)encryptData:(NSData *)anData
{
    int             length;
    uint8_t         *input;
    int             i, j, value, index;
    NSMutableData   *encodedData;
    uint8_t         *output;
    
    if( (length = (int)[anData length]) <= 0 ) {
        return nil;
    }
    
    encodedData = [NSMutableData dataWithLength:((length + 2)/3)*4];
    input = (uint8_t *)[anData bytes];
    output = (uint8_t *)[encodedData mutableBytes];
    
    for( i=0 ; i<length ; i+= 3 ) {
        value = 0;
        for( j=i ; j<(i+3) ; ++j ) {
            value <<= 8;
            if( j < length ) {
                value |= (0xFF & input[j]);
            }
        }
        index = (i/3)*4;
        output[index+0] =                    g_base64EncodingTable[(value >> 18) & 0x3F];
        output[index+1] =                    g_base64EncodingTable[(value >> 12) & 0x3F];
        output[index+2] = (i + 1) < length ? g_base64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[index+3] = (i + 2) < length ? g_base64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [NSData dataWithData:encodedData];
}

- (NSData *)decryptData:(NSData *)anData
{
    int             inputLength, outputLength;
    int             inputPoint, outputPoint;
    NSMutableData   *decodedData;
    char            *input;
    uint8_t         *output;
    char            i0, i1, i2, i3;
    
    if( (inputLength = (int)[anData length]) <= 0 ) {
        return nil;
    }
    if( (inputLength % 4) != 0 ) {
        return nil;
    }
    
    input = (char *)[anData bytes];
    while( (inputLength > 0) && (input[inputLength-1] == '=') ) {
        -- inputLength;
    }
    outputLength = inputLength*3/4;
    decodedData = [NSMutableData dataWithLength:outputLength];
    output = [decodedData mutableBytes];
    inputPoint = 0;
    outputPoint = 0;
    
    while( inputPoint < inputLength ) {
        i0 = input[inputPoint++];
        i1 = input[inputPoint++];
        i2 = inputPoint < inputLength ? input[inputPoint++] : 'A'; /* 'A' will decode to \0 */
        i3 = inputPoint < inputLength ? input[inputPoint++] : 'A';
        output[(int)outputPoint++] = (g_base64DecodingTable[(int)i0] << 2) | (g_base64DecodingTable[(int)i1] >> 4);
        if( outputPoint < outputLength ) {
            output[(int)outputPoint++] = ((g_base64DecodingTable[(int)i1] & 0xf) << 4) | (g_base64DecodingTable[(int)i2] >> 2);
        }
        if( outputPoint < outputLength ) {
            output[(int)outputPoint++] = ((g_base64DecodingTable[(int)i2] & 0x3) << 6) | g_base64DecodingTable[(int)i3];
        }
    }
    
    return [NSData dataWithData:decodedData];
}

- (BOOL)encryptData:(NSData *)anData toFilePath:(NSString *)path
{
    NSData *encryptedData;
    
    if( ([anData length] <= 0) || ([path length] <= 0) ) {
        return NO;
    }
    if( (encryptedData = [self encryptData:anData]) == nil ) {
        return NO;
    }
    
    return [encryptedData writeToFile:path atomically:YES];
}

- (NSData *)decryptDataFromFilePath:(NSString *)path
{
    if( [path length] <= 0 ) {
        return nil;
    }
    
    return [self decryptData:[NSData dataWithContentsOfFile:path]];
}

@end
