//
//  ObjSignMessage.h
//  example-ios
//
//

@interface ObjSignMessage : NSObject

@property(nonatomic, strong, nonnull) NSString *address;
@property(nonatomic, strong, nonnull) NSString *signature;

- (instancetype _Nullable)initWithAddress:(NSString *_Nonnull)address signature:(NSString *_Nonnull)signature;

@end

