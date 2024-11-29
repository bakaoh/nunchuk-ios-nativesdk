//
//  ObjTapsignerStatus.h
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 04/07/2022.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface ObjTapsignerStatus : NSObject
@property (nonatomic, strong) NSString *cardIdent;
@property (nonatomic, strong) NSString *currentDerivation;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *masterSignerId;
@property (nonatomic, strong) NSData *backupData;
@property (nonatomic, assign) NSInteger birthHeight;
@property (nonatomic, assign) NSInteger numberOfBackup;
@property (nonatomic, assign) NSInteger authDelay;
@property (nonatomic, assign) BOOL isTestnet;
@property (nonatomic, assign) BOOL isMasterSigner;
@property (nonatomic, assign) BOOL needSetup;
@end

NS_ASSUME_NONNULL_END
