//
//  ObjScriptNodeTransaction.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjSigningPath.h"

@implementation ObjSigningPath {
}

- (instancetype _Nullable)initWithScriptNodeIds:(NSArray<NSArray<NSString *> *>* _Nonnull)scriptNodeIds {
    ObjSigningPath *obj = [ObjSigningPath new];
    obj.scriptNodeIds = scriptNodeIds;
    return obj;
}

@end

@implementation ObjSigningPathFee {
}

- (instancetype _Nullable)initWithSigningPath:(ObjSigningPath* _Nonnull)signingPath amount:(int64_t)amount {
    ObjSigningPathFee *obj = [ObjSigningPathFee new];
    obj.signingPath = signingPath;
    obj.amount = amount;
    return obj;
}

@end
