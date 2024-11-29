//
//  ObjWallet.h
//  example-ios
//
//  Created by congtung private on 02/03/2021.
//

#ifndef ObjWallet_h
#define ObjWallet_h
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
@property(nonatomic, strong, nullable) NSString *type;
@property(nonatomic) int gapLimit;
@property(nonatomic) BOOL isNeedBackup;
@end

#endif /* ObjWallet_h */
