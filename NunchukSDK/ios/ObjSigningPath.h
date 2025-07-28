//
//  ObjSigningPath.h
//  example-ios
//
//

@interface ObjSigningPath : NSObject

@property(nonatomic, strong, nonnull) NSArray<NSArray<NSString *> *> *scriptNodeIds;

- (instancetype _Nullable)initWithScriptNodeIds:(NSArray<NSArray<NSString *> *>* _Nonnull)scriptNodeIds amount:(int64_t)amount;

@end


@interface ObjSigningPathFee : NSObject

@property(nonatomic, strong, nonnull) NSArray<ObjSigningPath *> *signingPaths;
@property(nonatomic, assign) int64_t amount;

- (instancetype _Nullable)initWithSigningPaths:(NSArray<ObjSigningPath *>* _Nonnull)signingPaths amount:(int64_t)amount;

@end
