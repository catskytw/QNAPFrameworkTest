//
//  QNAPFrameworkTestingTests.m
//  QNAPFrameworkTestingTests
//
//  Created by Change.Liao on 13/9/11.
//  Copyright (c) 2013年 QNAP. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <QNAPFramework/QNAPCommunicationManager.h>
#import <QNAPFramework/QNMyCloudManager.h>

#import <CocoaLumberjack/DDLog.h>
#import <Expecta/Expecta.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import <MagicalRecord/MagicalRecord.h>

#import "UserActivity.h"
#import "App.h"
#import "Response.h"

#define MyCloudServerBaseURL @"http://core.api.alpha-myqnapcloud.com"
#define CLIENT_ID @"521c609775413f6bfec8e59b"
#define CLIENT_SECRET @"LWvRWyHFNDENTZZGCp9kcOEGed18cW02KVnV6bfrvtBL0hpu"
#define ACCOUNT @"catskytw@gmail.com"
#define PASSWORD @"12345678"
#define NASURL @"http://changenas.myqnapcloud.com:8080"

@interface QNAPFrameworkTestingTests : XCTestCase
@property QNAPCommunicationManager *communicationManager;
@property QNMyCloudManager *myCloudManager;
@property QNFileStationAPIManager *fileStationManager;
@end

@implementation QNAPFrameworkTestingTests


- (void)setUp {
    
    
    [super setUp];
    [Expecta setAsynchronousTestTimeout:10];
    [[QNAPCommunicationManager share] settingMisc: nil];
    
    self.myCloudManager = [[QNAPCommunicationManager share] factoryForMyCloudManager:MyCloudServerBaseURL withClientId:CLIENT_ID withClientSecret:CLIENT_SECRET];
    [self.myCloudManager fetchOAuthToken:ACCOUNT
                            withPassword:PASSWORD
                        withSuccessBlock:^(AFOAuthCredential *credential) {
                            DDLogVerbose(@"credential success %@", credential.accessToken);
                        }
                        withFailureBlock:^(NSError *error){
                            DDLogError(@"token failure: %@", error);
                        }];
    EXP_expect(self.myCloudManager.rkObjectManager).willNot.beNil();
    
    self.fileStationManager = [[QNAPCommunicationManager share] factoryForFileStatioAPIManager:NASURL];
    [self.fileStationManager loginWithAccount:ACCOUNT
                                 withPassword:PASSWORD
                             withSuccessBlock:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult, QNFileLogin *loginInfo){
                                 DDLogVerbose(@"login success %@", loginInfo.authSid);
                             }
                             withFailureBlock:^(RKObjectRequestOperation *operation, NSError *error){
                             }];
    EXP_expect(self.fileStationManager.rkObjectManager).willNot.beNil();
}

- (void)tearDown {
    self.myCloudManager = nil;
    [QNAPCommunicationManager closeCommunicationManager];
    
    [super tearDown];
}

#pragma mark - TestCase
- (void)notTestToken {
    __block AFOAuthCredential *_credential = nil;
    [self.myCloudManager fetchOAuthToken:^(AFOAuthCredential *credential) {
        DDLogInfo(@"credential %@", credential.accessToken);
        _credential = credential;
    }
                        withFailureBlock:^(NSError *error) {
                            _credential = [AFOAuthCredential new];
                            DDLogError(@"error while acquiring accessToken %@", error);
                        }
     ];
    EXP_expect(_credential).willNot.beNil();
}

- (void)testReadMyInformation {
    __block RKObjectRequestOperation *_operation = nil;
    [self.myCloudManager readMyInformation:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        _operation = operation;
    }                    withFailiureBlock:^(RKObjectRequestOperation *operation, NSError *error, Response *response) {
        _operation = operation;
    }];
    
    EXP_expect(_operation).willNot.beNil();
}

- (void)testUpdateMyInformation{
    NSDictionary *userInfo = @{@"email":@"catskytw@gmail.com",
                               @"first_name":@"Change",
                               @"last_name":@"Chen",
                               @"mobile_number":@"0912345678",
                               @"language":@"chaaaaaaaaaaa",
                               @"gender":[NSNumber numberWithInt:1],
                               @"birthday":@"1976-10-20",
                               @"subscribed":[NSNumber numberWithBool:YES]
                               };
    __block RKObjectRequestOperation *_operation = nil;
    [self.myCloudManager updateMyInformation:userInfo
                            withSuccessBlock:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                _operation = operation;
                            }
                            withFailureBlock:^(RKObjectRequestOperation *operation, NSError *error, Response *response) {
                                _operation = operation;
                            }];
    
    EXP_expect(_operation).willNot.beNil();
}

- (void)testListMyActivities{
    __block RKObjectRequestOperation *_operation = nil;
    [self.myCloudManager listMyActivities:0
                                withLimit:10
                                   isDesc:YES
                         withSuccessBlock:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult){
                             _operation = operation;
                             NSArray *objs = [UserActivity MR_findAllSortedBy:@"created_at" ascending:YES];
                             DDLogInfo(@"All activity are listed below:");
                             for (UserActivity *thisActivity in objs) {
                                 DDLogInfo(@"thisActivity %@,\n app:%@", thisActivity, thisActivity.relationship_App.appId);
                             }
                         }
                         withFailureBlock:^(RKObjectRequestOperation *operation, NSError *error, Response *response){
                             _operation = operation;
                         }];
    EXP_expect(_operation).willNot.beNil();
}

- (void)testChangePassword{
    __block RKObjectRequestOperation *_operation = nil;
    [self.myCloudManager changeMyPassword:@"12345678"
                          withNewPassword:@"12345678"
                         withSuccessBlock:^(RKObjectRequestOperation *operation, RKMappingResult *mappingRestul){
                             Response *response = [mappingRestul firstObject];
                             DDLogInfo(@"changePassword response code:%@  message:%@",response.code, response.message);
                             _operation = operation;
                         }
                         withFailureBlock:^(RKObjectRequestOperation *operation, NSError *error, Response *response){
                             _operation = operation;
                         }];
    EXP_expect(_operation).willNot.beNil();
}

- (void)testLoginViaFileStation{
    __block RKObjectRequestOperation *_operation = nil;
    [self.fileStationManager loginWithAccount:ACCOUNT
                                 withPassword:PASSWORD
                             withSuccessBlock:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult, QNFileLogin *loginInfo){
                                 DDLogVerbose(@"login success %@", loginInfo.authSid);
                                 _operation = operation;
                             }
                             withFailureBlock:^(RKObjectRequestOperation *operation, NSError *error){
                                 _operation = operation;
                             }];
    EXP_expect(_operation).willNot.beNil();
}

@end
