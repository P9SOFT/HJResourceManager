//
//  HJResourceCipherRsa.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2014. 12. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <HJResourceManager/HJResourceCipherProtocol.h>

@interface HJResourceCipherRsa : NSObject <HJResourceCipherProtocol>
{
    SecCertificateRef   _certificateRef;
    SecPolicyRef        _policyRef;
    SecTrustRef         _trustRef;
    SecKeyRef           _publicKeyRef;
    size_t              _maximumSizeOfPlainText;
}

- (BOOL)loadPublicKeyFromData:(NSData *)publicKeyData;

@property (nonatomic, readonly) size_t maximumSizeOfPlainText;

@end
