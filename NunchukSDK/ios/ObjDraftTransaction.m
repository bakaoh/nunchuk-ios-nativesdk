//
//  ObjDraftTransaction.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjDraftTransaction.h"

@implementation ObjDraftTransaction {
}

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction IsCPFP:(BOOL)IsCPFP packageFeeRate:(NSInteger)packageFeeRate {
    ObjDraftTransaction *obj = [ObjDraftTransaction new];
    obj.transaction = transaction;
    obj.IsCPFP = IsCPFP;
    obj.packageFeeRate = packageFeeRate;
    return obj;
}

@end

