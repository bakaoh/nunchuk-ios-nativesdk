//
//  ObjDraftTransaction.h
//  example-ios
//
//

#import "ObjTransaction.h"
#import "ObjUnspentOutput.h"

@interface ObjDraftTransaction : NSObject

@property(nonatomic, strong, nonnull) ObjTransaction *transaction;
@property(nonatomic, assign) BOOL IsCPFP;
@property(nonatomic, assign) NSInteger packageFeeRate;
@property(nonatomic, strong, nonnull) NSArray *keySets;
@property(nonatomic, strong, nonnull) NSArray<ObjUnspentOutput *> *inputCoins;

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction IsCPFP:(BOOL)IsCPFP packageFeeRate:(NSInteger)packageFeeRate keySets:(NSArray *_Nonnull)keySets inputCoins:(NSArray<ObjUnspentOutput *> *_Nonnull)inputCoins;

@end

