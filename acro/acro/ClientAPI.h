//
//  ClientAPI
//  acro
//
//  Created by Admin on 3/05/15.
//  Copyright (c) 2015 acro. All rights reserved.
//

#import "AFHTTPSessionManager.h"

typedef void (^SuccessObjectBlock)(id object);
typedef void (^SuccessObjectsBlock)(NSArray *objects);
typedef void (^FailureBlock)(NSError* error);


@interface ClientAPI : NSObject

//- (instancetype)initWithBaseURL:(NSString *)baseURL;

/**
 Singleton object.
 */
+ (ClientAPI *)sharedAPI;



#pragma mark - Acronyms
- (void)getAcronymsForAbbreviation:(NSString*)abbreviation
                    withSuccess:(SuccessObjectsBlock)success
                           failure:(FailureBlock)failure;



@end