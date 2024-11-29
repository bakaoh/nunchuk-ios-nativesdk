//
//  ObjDraftRolloverTransaction.h
//  example-ios
//
//

#import "ObjTransaction.h"

@interface ObjDraftRolloverTransaction : NSObject

@property(nonatomic, strong, nonnull) ObjTransaction *transaction;
@property(nonatomic, strong, nonnull) NSArray *tagIds;
@property(nonatomic, strong, nonnull) NSArray *collectionIds;

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction tagIds:(NSArray *_Nonnull)tagIds collectionIds:(NSArray *_Nonnull)collectionIds;

@end

