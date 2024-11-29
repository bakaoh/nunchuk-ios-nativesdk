//
//  ObjAssistedWallet.h
//  example-ios
//
//

#import "ObjTapSignerKeyInfo.h"
#import "ObjMasterSigner.h"

@interface ObjKeyInfo : NSObject

@property(nonatomic, strong, nonnull) NSString *keyId;
@property(nonatomic, strong, nonnull) NSString *name;
@property(nonatomic, strong, nonnull) NSString *xfp;
@property(nonatomic, strong, nonnull) NSString *derivationPath;
@property(nonatomic, strong, nonnull) NSString *xpub;
@property(nonatomic, strong, nonnull) NSString *pubkey;
@property(nonatomic, assign) ObjCSignerType type;
@property(nonatomic, strong, nullable) ObjTapSignerKeyInfo *tapsigner;
@property(nonatomic, strong, nonnull) NSArray *tags;
@property(nonatomic, assign) BOOL isVisible;

@end

