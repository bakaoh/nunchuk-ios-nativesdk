//
//  ObjAssistedWallet.h
//  example-ios
//
//

@interface ObjTapSignerKeyInfo : NSObject

@property(nonatomic, strong, nonnull) NSString *cardId;
@property(nonatomic, strong, nonnull) NSString *version;
@property(nonatomic, assign) double birthHeight;
@property(nonatomic, assign) BOOL isTestnet;

@end
