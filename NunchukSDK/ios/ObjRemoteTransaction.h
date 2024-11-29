//
//  ObjRemoteTransaction.h
//  example-ios
//
//

@interface ObjRemoteTransaction : NSObject

@property(nonatomic, strong, nonnull) NSString *status;
@property(nonatomic, strong, nonnull) NSString *localWalletId;
@property(nonatomic, strong, nonnull) NSString *localTransactionId;
@property(nonatomic, strong, nonnull) NSString *transactionId;
@property(nonatomic, strong, nonnull) NSString *hex;
@property(nonatomic, strong, nonnull) NSString *rejectMessage;
@property(nonatomic, strong, nonnull) NSString *psbt;
@property(nonatomic, strong, nonnull) NSString *type;
@property(nonatomic, strong, nonnull) NSString *note;
@property(nonatomic, strong, nonnull) NSString *replaceTxId;
@property(nonatomic, assign) double broadcastTime;

@end

