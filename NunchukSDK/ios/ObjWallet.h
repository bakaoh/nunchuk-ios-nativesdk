//
//  ObjWallet.h
//  example-ios
//
//  Created by congtung private on 02/03/2021.
//

#ifndef ObjWallet_h
#define ObjWallet_h

typedef enum NunchukWalletTemplate {
    DEFAULT,
    DISABLE_KEY_PATH
} NunchukWalletTemplate;

@interface ObjWallet : NSObject
@property(nonatomic, strong, nullable) NSString* walletName;
@property(nonatomic, strong, nonnull) NSString* walletId;
@property(nonatomic, strong, nullable) NSString* desc;
@property(nonatomic, strong, nullable) NSString* addressType;
@property(nonatomic, strong, nullable) NSDate* createdAt;
@property(nonatomic, strong, nullable) NSString* messageToSign;
@property(nonatomic) NSInteger balance;
@property(nonatomic) int m;
@property(nonatomic, strong, nullable) NSMutableArray* signers;
@property(nonatomic) int n;
@property(nonatomic, assign) BOOL isEscrow;
@property(nonatomic, assign) BOOL isArchived;
@property(nonatomic, strong, nullable) NSString *type;
@property(nonatomic) int gapLimit;
@property(nonatomic) BOOL isNeedBackup;
@property(nonatomic, assign) NunchukWalletTemplate walletTemplate;
@property(nonatomic, strong, nullable) NSString *miniscript;
@property(nonatomic, strong, nullable) NSString *descriptor;
@property(nonatomic, readonly) BOOL isMiniscriptWallet;

@end

#endif /* ObjWallet_h */
