//
//  ObjGroupMessage.h
//  example-ios
//
//

@interface ObjGroupMessage : NSObject

@property(nonatomic, strong, nonnull) NSString *messageId;
@property(nonatomic, strong, nonnull) NSString *walletId;
@property(nonatomic, strong, nonnull) NSString *senderId;
@property(nonatomic, strong, nonnull) NSString *content;
@property(nonatomic, strong, nonnull) NSString *signerId;
@property(nonatomic, assign) double timestamp;

@end

