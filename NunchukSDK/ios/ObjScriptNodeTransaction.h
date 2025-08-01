//
//  ObjScriptNodeTransaction.h
//  example-ios
//
//

@interface ObjSigningPath : NSObject

@property(nonatomic, strong, nonnull) NSArray<NSArray<NSString *> *> *scriptNodeIds;

- (instancetype _Nullable)initWithScriptNodeIds:(NSArray<NSArray<NSString *> *>* _Nonnull)scriptNodeIds;

@end


@interface ObjSigningPathFee : NSObject

@property(nonatomic, strong, nonnull) ObjSigningPath *signingPath;
@property(nonatomic, assign) int64_t amount;

- (instancetype _Nullable)initWithSigningPath:(ObjSigningPath* _Nonnull)signingPath amount:(int64_t)amount;

@end
