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

typedef NS_ENUM(NSInteger, HJResourceManagerRequestStatus)
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
};

typedef NS_ENUM(NSInteger, HJResourceFetchFromType)
{
    HJResourceFetchFromTypeMemory,
    HJResourceFetchFromTypeRepository
};

typedef void(^HJResourceManagerCompleteBlock)(NSDictionary * _Nullable);

@interface HJResourceManager : HYManager

+ (HJResourceManager * _Nonnull)defaultHJResourceManager;

- (BOOL)standbyWithRepositoryPath:(NSString * _Nullable)path localJobWorkerName:(NSString * _Nullable)localJobWorkerName remoteJobWorkerName:(NSString * _Nullable)remoteJobWorkerName;
- (void)pauseTransfering;
- (void)resumeTransfering;
- (void)cancelTransfering;

- (id _Nullable)cipherForName:(NSString * _Nullable)name;
- (BOOL)setCipher:(id _Nullable)cipher forName:(NSString * _Nullable)name;
- (void)removeCipherForName:(NSString * _Nullable)name;
- (void)removeAllCiphers;
- (NSData * _Nullable)encryptData:(NSData * _Nullable)anData forName:(NSString * _Nullable)name;
- (NSData * _Nullable)decryptData:(NSData * _Nullable)anData forName:(NSString * _Nullable)name;
- (BOOL)encryptData:(NSData * _Nullable)anData toFilePath:(NSString * _Nullable)filePath forName:(NSString * _Nullable)name;
- (NSData * _Nullable)decryptDataFromFilePath:(NSString * _Nullable)filePath forName:(NSString * _Nullable)name;

- (id _Nullable)remakerForName:(NSString * _Nullable)name;
- (BOOL)setRemaker:(id _Nullable)remaker forName:(NSString * _Nullable)name;
- (void)removeRemakerForName:(NSString * _Nullable)name;
- (void)removeAllRemakers;
- (NSData * _Nullable)remakeData:(NSData * _Nullable)anData withParameter:(id _Nullable)anParameter forName:(NSString * _Nullable)name;

- (void)resourceForQuery:(NSDictionary * _Nullable)resourceQuery completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (void)resourceForQuery:(NSDictionary * _Nullable)resourceQuery cutInLine:(BOOL)cutInLine completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (NSDate * _Nullable)cachedDateOfResourceForQuery:(NSDictionary * _Nullable)resourceQuery;
- (BOOL)checkValidationOfResourceWithExpireTimeInterval:(NSTimeInterval)expireTimeInterval forQuery:(NSDictionary * _Nullable)resourceQuery;
- (id _Nullable)cachedResourceForQuery:(NSDictionary * _Nullable)resourceQuery;
- (id _Nullable)pickResourceFromMemoryCacheForQuery:(NSDictionary * _Nullable)resourceQuery;
- (void)updateCachedResourceForQuery:(NSDictionary * _Nullable)resourceQuery completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (BOOL)unloadResourceForQuery:(NSDictionary * _Nullable)resourceQuery;
- (BOOL)unloadAllResources;
- (void)removeResourceForQuery:(NSDictionary * _Nullable)resourceQuery completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (void)removeResourcesForElapsedTimeFromNow:(NSTimeInterval)elpasedTime completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (void)removeResourcesUnderMaximumBoundarySize:(NSUInteger)maximumBoundarySize completion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (void)removeAllResourcesWithCompletion:(HJResourceManagerCompleteBlock _Nullable)completion;
- (void)amountSizeOfAllResoursesWithCompletion:(HJResourceManagerCompleteBlock _Nullable)completion;

- (NSString * _Nullable)resourcePathFromResourceQuery:(NSDictionary * _Nullable)resourceQuery;
- (NSString * _Nullable)resourceKeyStringFromResourceQuery:(NSDictionary * _Nullable)resourceQuery;
- (NSString * _Nullable)filePathFromReosurceQuery:(NSDictionary * _Nullable)resourceQuery;
- (NSNumber * _Nullable)fileSizeFromReosurceQuery:(NSDictionary * _Nullable)resourceQuery;

@property (nonatomic, readonly) NSString * _Nullable repositoryPath;
@property (nonatomic, readonly) BOOL standby;
@property (nonatomic, readonly) NSUInteger usedMemorySize;
@property (nonatomic, assign) NSUInteger limitSizeOfMemory;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSInteger maximumConnection;

@end
