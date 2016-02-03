//
//  HJResourceExecutorLocalJob.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 4. 18.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <HJAsyncHttpDeliverer/HJAsyncHttpDeliverer.h>
#import "HJResourceCommon.h"
#import "HJResourceCipherProtocol.h"
#import "HJResourceRemakerProtocol.h"
#import "HJResourceExecutorLocalJob.h"

@interface HJResourceExecutorLocalJob (HJResourceExecutorLocalJobPrivate)

- (BOOL)checkValidationOfFileWithExpireTimeInterval:(NSTimeInterval)expireTimeInterval forFilePath:(NSString *)filePath;
- (NSUInteger)amountSizeOfPath:(NSString *)path;
- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJResourceExecutorLocalJobStatus)status;
- (void)loadResourceWithQuery:(id)anQuery;
- (void)updateResourceWithQuery:(id)anQuery;
- (void)removeResourceByPathWithQuery:(id)anQuery;
- (void)removeResourceByExpireTimeIntervalWithQuery:(id)anQuery;
- (void)removeResourceByBoundarySizeWithQuery:(id)anQuery;
- (void)removeAllResourcesWithQuery:(id)anQuery;
- (void)amountItemSizeWithQuery:(id)anQuery;

@end


@implementation HJResourceExecutorLocalJob

- (NSString *)name
{
    return HJResourceExecutorLocalJobName;
}

- (NSString *)brief
{
    return @"HJResourceManager's executor for local job such as load, remake, update, remove, calculate amount size of resources.";
}

- (BOOL)calledExecutingWithQuery:(id)anQuery
{
    HJResourceExecutorLocalJobOperation operation = (HJResourceExecutorLocalJobOperation)[[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyOperation] integerValue];
    
    switch( operation ) {
        case HJResourceExecutorLocalJobOperationLoad :
            [self loadResourceWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationUpdate :
            [self updateResourceWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationRemoveByPath :
            [self removeResourceByPathWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationRemoveByExpireTimeInterval :
            [self removeResourceByExpireTimeIntervalWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationRemoveByBoundarySize :
            [self removeResourceByBoundarySizeWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationRemoveAll :
            [self removeAllResourcesWithQuery:anQuery];
            break;
        case HJResourceExecutorLocalJobOperationAmountSize :
            [self amountItemSizeWithQuery:anQuery];
            break;
        default :
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusUnknownOperation]];
            break;
    }
    
    return YES;
}

- (BOOL)calledCancelingWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusCanceled]];
    
    return YES;
}

- (BOOL)checkValidationOfFileWithExpireTimeInterval:(NSTimeInterval)expireTimeInterval forFilePath:(NSString *)filePath
{
    if( [filePath length] == 0 ) {
        return NO;
    }
    
    NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    if( attribute == nil ) {
        return NO;
    }
    NSDate *createDate = [attribute objectForKey:NSFileCreationDate];
    if( createDate == nil ) {
        return YES;
    }
    NSDate *expireDate = [createDate dateByAddingTimeInterval:expireTimeInterval];
    if( expireDate == nil ) {
        return NO;
    }
    
    return ([expireDate compare:[NSDate date]] != NSOrderedDescending);
}

- (NSUInteger)amountSizeOfPath:(NSString *)path
{
    if( [path length] == 0 ) {
        return 0;
    }
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    if( [fileNames count] == 0 ) {
        return 0;
    }
    
    NSUInteger amountSize = 0;
    for( NSString *fileName in fileNames ) {
        if( [[fileName substringToIndex: 1] isEqualToString: @"."] == YES ) {
            continue;
        }
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if( [[attribute objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory] == YES ) {
            amountSize += [self amountSizeOfPath:filePath];
        } else if( [[attribute objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] == YES ) {
            amountSize += [[attribute objectForKey:NSFileSize] unsignedIntegerValue];
        }
    }
    
    return amountSize;

}

- (id)resultForExpiredQuery:(id)anQuery
{
    return [self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusExpired];
}

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJResourceExecutorLocalJobStatus)status
{
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParametersFromDictionary:[anQuery paramDict]];
        [result setParameter:@((NSInteger)status) forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    }
    
    return result;
}

- (void)loadResourceWithQuery:(id)anQuery
{
    NSString *resourcePath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    if( [resourcePath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    NSString *originalFilePath = [resourcePath stringByAppendingPathComponent:HJResourceOriginalFileName];
    HJResourceDataType dataType;
    if( [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataType] != nil ) {
        dataType = (HJResourceDataType)[[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataType] integerValue];
    } else {
        NSString *mimeTypeFilePath = [resourcePath stringByAppendingPathComponent:HJResourceMimeTypeFileName];
        NSString *mimeType = [NSString stringWithContentsOfFile:mimeTypeFilePath encoding:NSUTF8StringEncoding error:nil];
        dataType = [HJResourceCommon dataTypeFromMimeType:mimeType];
    }
    
    id cipher = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyCipher];
    id remaker = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyRemaker];
    id remakerParameter = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyRemakerParameter];
    NSNumber *expireTimeIntervalNumber = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyExpireTimeInterval];
    if( expireTimeIntervalNumber != nil ) {
        if( [self checkValidationOfFileWithExpireTimeInterval:(NSTimeInterval)[expireTimeIntervalNumber unsignedIntegerValue] forFilePath:originalFilePath] == NO ) {
            if( [[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
                return;
            }
        }
    }
    
    NSData *data;
    if( remaker == nil ) {
        if( (data = [NSData dataWithContentsOfFile:originalFilePath]) != nil ) {
            if( cipher != nil ) {
                data = [cipher decryptData:data];
            }
        }
    } else {
        NSString *remakerFilePath;
        NSString *subIdentifier = [remaker subIdentifierForParameter:remakerParameter];
        if( [subIdentifier length] > 0 ) {
            remakerFilePath = [resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@", [remaker identifier], subIdentifier]];
        } else {
            remakerFilePath = [resourcePath stringByAppendingPathComponent:[remaker identifier]];
        }
        if( (data = [NSData dataWithContentsOfFile:remakerFilePath]) != nil ) {
            if( cipher != nil ) {
                data = [cipher decryptData:data];
            }
        } else {
            if( (data = [NSData dataWithContentsOfFile:originalFilePath]) != nil ) {
                if( cipher != nil ) {
                    data = [cipher decryptData:data];
                }
                if( (data = [remaker remakerData:data withParameter:remakerParameter]) != nil ) {
                    if( cipher != nil ) {
                        [cipher encryptData:data toFilePath:remakerFilePath];
                    } else {
                        [data writeToFile:remakerFilePath atomically:YES];
                    }
                }
            }
        }
    }
    if( data == nil ) {
        if( [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyResourceUrl] == nil ) {
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        } else {
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusFileNotFound]];
        }
        return;
    }
    
    id dataObject;
    switch( dataType ) {
        case HJResourceDataTypeData :
            dataObject = data;
            break;
        case HJResourceDataTypeString :
            dataObject = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            break;
        case HJResourceDataTypeImage :
            dataObject = [UIImage imageWithData:data];
            break;
        default :
            dataObject = nil;
            break;
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusLoaded] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [result setParameter:dataObject forKey:HJResourceExecutorLocalJobParameterKeyDataObject];
    [self storeResult:result];
}

- (void)updateResourceWithQuery:(id)anQuery
{
    NSString *resourcePath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    if( [resourcePath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    NSString *originalFilePath = [resourcePath stringByAppendingPathComponent:HJResourceOriginalFileName];
    NSString *mimeTypeFilePath = [resourcePath stringByAppendingPathComponent:HJResourceMimeTypeFileName];
    NSString *mimeType = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyMimeType];
    if( mimeType == nil ) {
        if( [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataType] != nil ) {
            HJResourceDataType dataType = (HJResourceDataType)[[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataType] integerValue];
            switch( dataType ) {
                case HJResourceDataTypeString :
                    mimeType = @"text/plain";
                    break;
                case HJResourceDataTypeImage :
                    mimeType = @"image/jpeg";
                    break;
                default :
                    break;
            }
        } else {
            mimeType = [NSString stringWithContentsOfFile:mimeTypeFilePath encoding:NSUTF8StringEncoding error:nil];
        }
    }
    id dataObject = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataObject];
    if( [dataObject isKindOfClass:[NSString class]] == YES ) {
        if( (HJResourceDataType)[[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyDataType] integerValue] == HJResourceDataTypeFilePath ) {
            dataObject = [NSData dataWithContentsOfFile:(NSString *)dataObject];
        } else {
            dataObject = [((NSString *)dataObject) dataUsingEncoding:NSUTF8StringEncoding];
            if( mimeType == nil ) {
                mimeType = @"text/plain";
            }
        }
    } else if( [dataObject isKindOfClass:[UIImage class]] == YES ) {
        dataObject = UIImageJPEGRepresentation((UIImage *)dataObject, 1.0f);
        if( mimeType == nil ) {
            mimeType = @"image/jpeg";
        }
    } else {
        if( [dataObject isKindOfClass:[NSData class]] == NO ) {
            dataObject = nil;
        }
    }
    
    if( dataObject == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    id cipher = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyCipher];
    
    [[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil];
    if( [[NSFileManager defaultManager] createDirectoryAtPath:resourcePath withIntermediateDirectories:YES attributes:nil error:nil] == NO ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    BOOL updated = NO;
    if( cipher == nil ) {
        updated = [((NSData *)dataObject) writeToFile:originalFilePath atomically:YES];
    } else {
        updated = [cipher encryptData:(NSData *)dataObject toFilePath:originalFilePath];
    }
    if( updated == NO ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    if( ([mimeType length] > 0) && ([mimeTypeFilePath length] > 0) ) {
        [mimeType writeToFile:mimeTypeFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusUpdated] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [self storeResult:result];
}

- (void)removeResourceByPathWithQuery:(id)anQuery
{
    NSString *resourcePath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    if( [resourcePath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    
    if( [[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil] == NO ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusRemoved] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [self storeResult:result];
}

- (void)removeResourceByExpireTimeIntervalWithQuery:(id)anQuery
{
    NSString *repositoryPath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    NSTimeInterval expireTimeInterval = (NSTimeInterval)[[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyExpireTimeInterval] doubleValue];
    if( [repositoryPath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:repositoryPath error:nil];
    if( [fileNames count] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    
    for( NSString *fileName in fileNames ) {
        if( [[fileName substringToIndex: 1] isEqualToString: @"."] == YES ) {
            continue;
        }
        NSString *filePath = [repositoryPath stringByAppendingPathComponent:fileName];
        NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSDate *creationDate = [attribute objectForKey:NSFileCreationDate];
        if( creationDate == nil ) {
            continue;
        }
        if( [creationDate timeIntervalSinceNow] <= -expireTimeInterval ) {
            if( [[NSFileManager defaultManager] removeItemAtPath:filePath error: nil] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
                return;
            }
        }
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusRemoved] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [self storeResult:result];
}

- (void)removeResourceByBoundarySizeWithQuery:(id)anQuery
{
    NSString *repositoryPath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    NSUInteger boundarySize = [[anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyBoundarySize] unsignedIntegerValue];
    if( [repositoryPath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    NSUInteger amountSize = [self amountSizeOfPath:repositoryPath];
    
    if( boundarySize < amountSize ) {
        NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:repositoryPath error:nil];
        if( [fileNames count] == 0 ) {
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
            return;
        }
        NSMutableArray *sortedFileNames = [[NSMutableArray alloc] initWithArray:fileNames];
        if( [sortedFileNames count] == 0 ) {
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
            return;
        }
        [sortedFileNames sortUsingComparator:^NSComparisonResult(id _Nonnull fileNameA, id _Nonnull fileNameB) {
            NSString *pathA = [repositoryPath stringByAppendingPathComponent:(NSString *)fileNameA];
            NSString *pathB = [repositoryPath stringByAppendingPathComponent:(NSString *)fileNameB];
            NSDate *dateA = [[[NSFileManager defaultManager] attributesOfItemAtPath:pathA error:nil] objectForKey:NSFileCreationDate];
            NSDate *dateB = [[[NSFileManager defaultManager] attributesOfItemAtPath:pathB error:nil] objectForKey:NSFileCreationDate];
            return [dateA compare:dateB];
        }];
        for( NSString *fileName in sortedFileNames ) {
            if( [[fileName substringToIndex: 1] isEqualToString: @"."] == YES ) {
                continue;
            }
            NSString *filePath = [repositoryPath stringByAppendingPathComponent:fileName];
            NSInteger itemSize = [self amountSizeOfPath:filePath];
            amountSize -= itemSize;
            if( [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
                return;
            }
            if( amountSize <= boundarySize ) {
                break;
            }
        }
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusRemoved] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [self storeResult:result];
}

- (void)removeAllResourcesWithQuery:(id)anQuery
{
    NSString *repositoryPath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyRepositoryPath];
    if( [repositoryPath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:repositoryPath error:nil];
    if( [fileNames count] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    
    for( NSString *fileName in fileNames ) {
        if( [[fileName substringToIndex: 1] isEqualToString: @"."] == YES ) {
            continue;
        }
        NSString *filePath = [repositoryPath stringByAppendingPathComponent:fileName];
        if( [[NSFileManager defaultManager] removeItemAtPath:filePath error: nil] == NO ) {
            [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
            return;
        }
    }
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusRemoved] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [self storeResult:result];
}

- (void)amountItemSizeWithQuery:(id)anQuery
{
    NSString *resourcePath = [anQuery parameterForKey:HJResourceExecutorLocalJobParameterKeyResourcePath];
    if( [resourcePath length] == 0 ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInvalidParameter]];
        return;
    }
    
    NSUInteger amountSize = [self amountSizeOfPath:resourcePath];
    
    HYResult *result = [HYResult resultWithName:self.name];
    if( result == nil ) {
        [self storeResult:[self resultForQuery:anQuery withStatus:HJResourceExecutorLocalJobStatusInternalError]];
        return;
    }
    [result setParametersFromDictionary:[anQuery paramDict]];
    [result setParameter:[NSNumber numberWithInt:HJResourceExecutorLocalJobStatusCalculated] forKey:HJResourceExecutorLocalJobParameterKeyStatus];
    [result setParameter:@(amountSize) forKey:HJResourceExecutorLocalJobParameterKeyDataObject];
    [self storeResult:result];
}

@end
