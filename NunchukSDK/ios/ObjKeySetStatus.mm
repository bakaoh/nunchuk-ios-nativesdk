//
//  ObjKeySetStatus.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjKeySetStatus.h"
#include <nunchuk.h>
#import "ObjTransaction.h"
#import <extensions/ObjTransactionLibrary.h>

using namespace nunchuk;

@implementation ObjKeySetStatus {
}

- (instancetype _Nullable)initKeySetStatus:(KeysetStatus *_Nullable)keysetStatus {
    ObjKeySetStatus *obj = [ObjKeySetStatus new];
    obj.status = [ObjTransaction transactionStatusFrom:keysetStatus->first];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (auto keySet: keysetStatus->second) {
        StringIntPair * pair = [[StringIntPair alloc] init];
        pair.key = [NSString stringWithUTF8String:keySet.first.c_str()];
        pair.value = keySet.second == true ? 1 : 0;
        [array addObject:pair];
    }
    obj.keySetStatus = [array copy];
    return obj;
}

@end
