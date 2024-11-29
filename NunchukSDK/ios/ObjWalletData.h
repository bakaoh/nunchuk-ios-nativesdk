//
//  ObjWalletData.h
//  example-ios
//
//

#import "ObjWallet.h"

@interface ObjWalletData : NSObject

@property(nonatomic, strong, nonnull) ObjWallet *wallet;
@property(nonatomic, strong, nonnull) NSString *bsms;
@property(nonatomic, strong, nonnull) NSString *firstAddress;

- (instancetype _Nullable)initWithWallet:(ObjWallet *_Nonnull)wallet bsms:(NSString *_Nonnull)bsms firstAddress:(NSString *_Nonnull)firstAddress;

@end

