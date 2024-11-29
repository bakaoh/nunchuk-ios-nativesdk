//
//  ObjCoinCollection.h
//  example-ios
//
//

@interface ObjCoinCollection : NSObject

@property(nonatomic, assign) int collectionId;
@property(nonatomic, strong, nonnull) NSString *name;
@property(nonatomic, assign) BOOL autoLockEnabled;
@property(nonatomic, strong, nonnull) NSArray *addCoinsWithTagIds;
@property(nonatomic, assign) BOOL addCoinsWithoutTagEnabled;

- (instancetype _Nullable)initWithCollectionId:(int)collectionId name:(NSString *_Nonnull)name;
- (instancetype _Nullable)initWithCollectionId:(int)collectionId name:(NSString *_Nonnull)name autoLockEnabled:(BOOL)autoLockEnabled addCoinsWithTagIds:(NSArray *_Nonnull)addCoinsWithTagIds addCoinsWithoutTagEnabled:(BOOL)addCoinsWithoutTagEnabled;
@end
