//
//  HJResourceCipherRsa.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2014. 12. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJResourceCipherRsa.h"

@interface HJResourceCipherRsa()
{
    SecCertificateRef   _certificateRef;
    SecPolicyRef        _policyRef;
    SecTrustRef         _trustRef;
    SecKeyRef           _publicKeyRef;
    size_t              _maximumSizeOfPlainText;
}
@end

@implementation HJResourceCipherRsa

@synthesize maximumSizeOfPlainText = _maximumSizeOfPlainText;

- (void)dealloc
{
    if( _publicKeyRef != NULL ) {
        CFRelease(_publicKeyRef);
        _publicKeyRef = NULL;
    }
    if( _trustRef != NULL ) {
        CFRelease(_trustRef);
        _trustRef = NULL;
    }
    if( _policyRef != NULL ) {
        CFRelease(_policyRef);
        _policyRef = NULL;
    }
    if( _certificateRef != NULL ) {
        CFRelease(_certificateRef);
        _certificateRef = NULL;
    }
}

- (BOOL)loadPublicKeyFromData:(NSData *)publicKeyData
{
    OSStatus            status;
    SecTrustResultType  trustResultType;
    
    if( publicKeyData.length <= 0 ) {
        return NO;
    }
    if( (_certificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)(publicKeyData))) == NULL ) {
        return NO;
    }
    if( (_policyRef = SecPolicyCreateBasicX509()) == NULL ) {
        return NO;
    }
    if( (status = SecTrustCreateWithCertificates(_certificateRef, _policyRef, &_trustRef)) != 0 ) {
        return NO;
    }
    if( (status = SecTrustEvaluate(_trustRef, &trustResultType)) != 0 ) {
        return NO;
    }
    if( (_publicKeyRef = SecTrustCopyPublicKey(_trustRef)) == NULL ) {
        return NO;
    }
    _maximumSizeOfPlainText = SecKeyGetBlockSize(_publicKeyRef) - 12;
    
    return YES;
}

- (NSData *)encryptData:(NSData *)anData
{
    void        *plainBuffer;
    size_t      plainLength;
    void        *cipherBuffer;
    size_t      cipherLength;
    OSStatus    status;
    NSData  *cipherData;
    
    if( (plainLength = anData.length) > _maximumSizeOfPlainText ) {
        return nil;
    }
    
    if( (plainBuffer = malloc(plainLength)) == NULL ) {
        return nil;
    }
    [anData getBytes:plainBuffer length:plainLength];
    cipherLength = 128;
    if( (cipherBuffer = malloc(cipherLength)) == NULL ) {
        free(plainBuffer);
        return nil;
    }
    if( (status = SecKeyEncrypt(_publicKeyRef, kSecPaddingPKCS1, plainBuffer, plainLength, cipherBuffer, &cipherLength)) != 0 ) {
        free(plainBuffer);
        free(cipherBuffer);
        return nil;
    }
    cipherData = [NSData dataWithBytes:cipherBuffer length:cipherLength];
    free(plainBuffer);
    free(cipherBuffer);
    
    return cipherData;
}

- (NSData *)decryptData:(NSData *)anData
{
    return nil;
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
