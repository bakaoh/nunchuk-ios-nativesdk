//
//  ObjDraftTransaction.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjDraftTransaction.h"

@implementation ObjDraftTransaction {
}

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction IsCPFP:(BOOL)IsCPFP packageFeeRate:(NSInteger)packageFeeRate keySets:(NSArray *_Nonnull)keySets inputCoins:(NSArray<ObjUnspentOutput *> *)inputCoins {
    ObjDraftTransaction *obj = [ObjDraftTransaction new];
    obj.transaction = transaction;
    obj.IsCPFP = IsCPFP;
    obj.packageFeeRate = packageFeeRate;
    obj.keySets = keySets;
    obj.inputCoins = inputCoins;
    return obj;
}

@end

