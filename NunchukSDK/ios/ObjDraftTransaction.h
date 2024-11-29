//
//  ObjDraftTransaction.h
//  example-ios
//
//

#import "ObjTransaction.h"

@interface ObjDraftTransaction : NSObject

@property(nonatomic, strong, nonnull) ObjTransaction *transaction;
@property(nonatomic, assign) BOOL IsCPFP;
@property(nonatomic, assign) NSInteger packageFeeRate;

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction IsCPFP:(BOOL)IsCPFP packageFeeRate:(NSInteger)packageFeeRate;

@end

