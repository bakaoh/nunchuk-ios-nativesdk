//
//  ObjCoinTag.h
//  example-ios
//
//

@interface ObjCoinTag : NSObject

@property(nonatomic, assign) int tagId;
@property(nonatomic, strong, nonnull) NSString *name;
@property(nonatomic, strong, nonnull) NSString *color;

- (instancetype _Nullable)initWithTagId:(int)tagId name:(NSString *_Nonnull)name color:(NSString *_Nonnull)color;

@end

