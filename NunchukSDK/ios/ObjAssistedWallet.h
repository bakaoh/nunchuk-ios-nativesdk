//
//  ObjAssistedWallet.h
//  example-ios
//
//

@interface ObjAssistedWallet : NSObject

@property(nonatomic, strong, nonnull) NSString *walletId;
@property(nonatomic, strong, nonnull) NSString *localId;
@property(nonatomic, strong, nonnull) NSString *name;
@property(nonatomic, strong, nonnull) NSString *desc;
@property(nonatomic, strong, nonnull) NSString *bsms;
@property(nonatomic, strong, nonnull) NSArray *signers;
@property(nonatomic, strong, nonnull) NSString *status;

@end
