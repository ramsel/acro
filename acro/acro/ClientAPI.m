//
//  ClientAPI.m
//  acro
//
//  Created by Admin on 3/05/15.
//  Copyright (c) 2015 acro. All rights reserved.
//

#import "ClientAPI.h"
#import "AFNetworking.h"

NSString *const API_URL = @"http://www.nactem.ac.uk/software/acromine/dictionary.py";


#define kData @"data"
#define kKeyAccessToken @"token"


@interface ClientAPI ()
{
    dispatch_queue_t mBackgroundQueue;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;

@property (nonatomic, assign) BOOL alertShowing;

@end

@implementation ClientAPI


#pragma mark - Singleton

+ (ClientAPI *)sharedAPI
{
    static ClientAPI *sharedClientAPI;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClientAPI = [[ClientAPI alloc] init];

    });
    
    return sharedClientAPI;
}


#pragma mark - Lifecycle
- (id)init {
    if (self = [super init])
    {
       
        NSURL* baseURL = [NSURL URLWithString:API_URL];
        self.operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        self.operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        mBackgroundQueue = dispatch_queue_create("background", NULL);
        
    }
    return self;
}

#pragma mark - Base Call

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
  responseModel:(Class)modelClass
        success:(void (^)(NSDictionary *responseObject))success
        failure:(void (^)(NSError* error, NSInteger statusCode))failure
{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];

    NSString *percentageEscapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self.operationManager GET:percentageEscapedPath
                    parameters:params
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           NSDictionary *responseDictionary = (NSDictionary *)responseObject;
                        
                           success(responseDictionary);
                           
                       }
                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           
                           if ([operation.error code] == -1009) [self showOfflineAlert];

                           failure(error,[[operation response] statusCode]);
                       }];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
   responseModel:(Class)modelClass
         success:(void (^)(NSDictionary *responseObject))success
         failure:(void (^)(NSError* error, NSInteger statusCode))failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];

    [self.operationManager POST:path
                     parameters:params
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            NSDictionary *responseDictionary = (NSDictionary *)responseObject;
                            
                            if ([[responseObject objectForKey:@"status"] isEqual:@(200)]) {
                                
                                NSString* message = [responseObject objectForKey:@"message"];
                                failure([self errorWithMessage:message],[[operation response] statusCode]);
                                return;
                            }
                            
                            success(responseDictionary);
                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                            if ([operation.error code] == -1009) [self showOfflineAlert];

                            failure(error,[[operation response] statusCode]);
                        }];
}


- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
     responseModel:(Class)modelClass
           success:(void (^)(void))success
           failure:(void (^)(NSError* error, NSInteger statusCode))failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    [self.operationManager DELETE:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            
            if ([operation.error code] == -1009) [self showOfflineAlert];

            failure(error,[[operation response] statusCode]);
        }
    }];
}

#pragma mark - Base Operations
- (void)getObjectsWithParameters:(NSDictionary *)parameters
                      objectPath:(NSString*)objectPath
                        withSuccess:(SuccessObjectsBlock)success
                            failure:(FailureBlock)failure
{
    
    [self getPath:objectPath parameters:parameters responseModel:[NSDictionary class] success:^(id response) {
        if(success)
        {
            NSError *error = nil;
            
            NSArray *responseData;
            if (response != nil) {
                responseData = [NSJSONSerialization JSONObjectWithData:response
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
            }
            
            NSArray* objects = [NSArray new];
            if (responseData.count > 0) {
                NSDictionary* responseDict = responseData[0];
                objects = [responseDict objectForKey:@"lfs"];
            }
            
            // callback
            success(objects);
        }
    } failure:^(NSError *error, NSInteger statusCode) {
        if(failure)
        {
            failure(error);
        }
    }];
}




#pragma mark - Acronyms
- (void)getAcronymsForAbbreviation:(NSString*)abbreviation
                      withSuccess:(SuccessObjectsBlock)success
                          failure:(FailureBlock)failure
{
    if (!abbreviation) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"No abbreviation passed" forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:@"network" code:200 userInfo:details];
        failure(error);
        return;
    }
    
    NSDictionary* parameters = @{ @"sf" : abbreviation };
    
    [self getObjectsWithParameters:parameters objectPath:API_URL withSuccess:success failure:failure];
}




#pragma mark - Reachability
- (void) setupReachibility {
    
    // Setup reachability
    NSOperationQueue *operationQueue = self.operationManager.operationQueue;
    [self.operationManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
                
                // Suspend operation
                [operationQueue setSuspended:YES];
            }
            default:
                [operationQueue setSuspended:YES];
                break;
        }
    }];
    
    [self.operationManager.reachabilityManager startMonitoring];
}

- (void)showOfflineAlert {
    
    if (self.alertShowing) return;
    
    // Show alert
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:@"No network connection. Please connect to the internet to continue using the app." forKey:NSLocalizedDescriptionKey];
    NSError*error = [NSError errorWithDomain:@"network" code:200 userInfo:details];
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:[NSString stringWithFormat:@"%@",[error localizedDescription]]
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    self.alertShowing = YES;
    [message show];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.alertShowing = NO;
}




#pragma mark - Error
- (NSError*)errorWithMessage:(NSString*)message {
    
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"network" code:200 userInfo:details];

}





@end