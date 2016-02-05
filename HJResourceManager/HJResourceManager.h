//
//  HJResourceManager.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 16.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>
#import <HJResourceManager/HJResourceCommon.h>
#import <HJResourceManager/HJResourceRemakerProtocol.h>
#import <HJResourceManager/HJResourceCipherProtocol.h>

#define     HJResourceManagerNotification                   @"HJResourceManagerNotification"

#define     HJResourceManagerParameterKeyRequestStatus                  @"HJResourceManagerParameterKeyRequestStatus"
#define     HJResourceManagerParameterKeyResourceQuery                  @"HJResourceManagerParameterKeyResourceQuery"
#define     HJResourceManagerParameterKeyRemoteResourceFlag             @"HJResourceManagerParameterKeyRemoteResourceFlag"
#define     HJResourceManagerParameterKeyCompleteBlock                  @"HJResourceManagerParameterKeyCompleteBlock"
#define		HJResourceManagerParameterKeyDataObject                     @"HJResourceManagerParameterKeyDataObject"
#define		HJResourceManagerParameterKeyAsyncHttpDelivererIssuedId     @"HJResourceManagerParameterKeyAsyncHttpDelivererIssuedId"

typedef enum _HJResourceManagerRequestStatus_
{
    HJResourceManagerRequestStatusIdle,
    HJResourceManagerRequestStatusLoaded,
    HJResourceManagerRequestStatusLoadFailed,
    HJResourceManagerRequestStatusDownloadStarted,
    HJResourceManagerRequestStatusDownloaded,
    HJResourceManagerRequestStatusDownloadFailed,
    HJResourceManagerRequestStatusUpdated,
    HJResourceManagerRequestStatusUpdateFailed,
    HJResourceManagerRequestStatusRemoved,
    HJResourceManagerRequestStatusRemoveFailed,
    HJResourceManagerRequestStatusCalculated,
    HJResourceManagerRequestStatusCalculateFailed,
    HJResourceManagerRequestStatusUnknownError
    
} HJResourceManagerRequestStatus;

typedef enum _HJResourceFetchFromType_
{
    HJResourceFetchFromTypeMemory,
    HJResourceFetchFromTypeRepository
    
} HJResourceFetchFromType;

typedef void(^HJResourceManagerCompleteBlock)(NSDictionary *);

@interface HJResourceManager : HYManager
{
    BOOL                    _standby;
    BOOL                    _paused;
    NSUInteger              _usedMemorySize;
    NSUInteger              _limitSizeOfMemory;
    NSString                *_repositoryPath;
    NSLock                  *_lockForResourceDict;
    NSMutableDictionary     *_loadedResourceDict;
    NSMutableArray          *_referenceOrder;
    NSMutableDictionary     *_requestingResourceKeyDict;
    NSLock                  *_lockForHashKeyDict;;
    NSMutableDictionary     *_loadedResourceKeyDict;
    NSMutableDictionary     *_loadedHashKeyDict;
    NSLock                  *_lockForSupportDict;
    NSMutableDictionary     *_remakerDict;
    NSMutableDictionary     *_cipherDict;
}

+ (HJResourceManager *)defaultManager;

- (BOOL)standbyWithRepositoryPath:(NSString *)path localJobWorkerName:(NSString *)localJobWorkerName remoteJobWorkerName:(NSString *)remoteJobWorkerName;
- (void)pauseTransfering;
- (void)resumeTransfering;
- (void)cancelTransfering;

- (id)cipherForName:(NSString *)name;
- (BOOL)setCipher:(id)cipher forName:(NSString *)name;
- (void)removeCipherForName:(NSString *)name;
- (void)removeAllCiphers;
- (NSData *)encryptData:(NSData *)anData forName:(NSString *)name;
- (NSData *)decryptData:(NSData *)anData forName:(NSString *)name;
- (BOOL)encryptData:(NSData *)anData toFilePath:(NSString *)filePath forName:(NSString *)name;
- (NSData *)decryptDataFromFilePath:(NSString *)filePath forName:(NSString *)name;

- (id)remakerForName:(NSString *)name;
- (BOOL)setRemaker:(id)remaker forName:(NSString *)name;
- (void)removeRemakerForName:(NSString *)name;
- (void)removeAllRemakers;
- (NSData *)remakeData:(NSData *)anData withParameter:(id)anParameter forName:(NSString *)name;

- (void)resourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion;
- (NSDate *)cachedDateOfResourceForQuery:(NSDictionary *)resourceQuery;
- (BOOL)checkValidationOfResourceWithExpireTimeInterval:(NSTimeInterval)expireTimeInterval forQuery:(NSDictionary *)resourceQuery;
- (id)cachedResourceForQuery:(NSDictionary *)resourceQuery;
- (id)pickResourceFromMemoryCacheForQuery:(NSDictionary *)resourceQuery;
- (void)updateCachedResourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion;
- (BOOL)unloadResourceForQuery:(NSDictionary *)resourceQuery;
- (BOOL)unloadAllResources;
- (void)removeResourceForQuery:(NSDictionary *)resourceQuery completion:(HJResourceManagerCompleteBlock)completion;
- (void)removeResourcesForElapsedTimeFromNow:(NSTimeInterval)elpasedTime completion:(HJResourceManagerCompleteBlock)completion;
- (void)removeResourcesUnderMaximumBoundarySize:(NSUInteger)maximumBoundarySize completion:(HJResourceManagerCompleteBlock)completion;
- (void)removeAllResourcesWithCompletion:(HJResourceManagerCompleteBlock)completion;
- (void)amountSizeOfAllResoursesWithCompletion:(HJResourceManagerCompleteBlock)completion;

- (NSString *)resourcePathFromResourceQuery:(NSDictionary *)resourceQuery;
- (NSString *)resourceKeyStringFromResourceQuery:(NSDictionary *)resourceQuery;
- (NSString *)filePathFromReosurceQuery:(NSDictionary *)resourceQuery;
- (NSNumber *)fileSizeFromReosurceQuery:(NSDictionary *)resourceQuery;

@property (nonatomic, readonly) NSString *repositoryPath;
@property (nonatomic, readonly) BOOL standby;
@property (nonatomic, readonly) NSUInteger usedMemorySize;
@property (nonatomic, assign) NSUInteger limitSizeOfMemory;

@end
