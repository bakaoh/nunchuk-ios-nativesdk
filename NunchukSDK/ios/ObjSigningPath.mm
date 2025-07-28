//
//  ObjWalletData.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjSigningPath.h"

@implementation ObjSigningPath {
}

- (instancetype _Nullable)initWithScriptNodeIds:(NSArray<NSArray<NSString *> *>* _Nonnull)scriptNodeIds amount:(int64_t)amount {
    ObjSigningPath *obj = [ObjSigningPath new];
    obj.scriptNodeIds = scriptNodeIds;
    return obj;
}

@end

@implementation ObjSigningPathFee {
}

- (instancetype _Nullable)initWithSigningPaths:(NSArray<ObjSigningPath *>* _Nonnull)signingPaths amount:(int64_t)amount {
    ObjSigningPathFee *obj = [ObjSigningPathFee new];
    obj.signingPaths = signingPaths;
    obj.amount = amount;
    return obj;
}

@end
