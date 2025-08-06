//
//  ObjCoinGroup.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#include <nunchuk.h>
#import "ObjCoinGroup.h"
#import <extensions/ObjCoinGroup+Extension.h>
#import <extensions/ObjUnspentOutputLibrary.h>

using namespace nunchuk;

@implementation ObjCoinGroup {
}

- (instancetype _Nullable)initWithCoinGroup:(CoinsGroup)coinsGroup {
    ObjCoinGroup *obj = [ObjCoinGroup new];
    std::vector<UnspentOutput> coinsC = coinsGroup.first;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:coinsC.size()];
    for (auto &coin : coinsC) {
        ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
        [array addObject:obj];
    }
    obj.coins = array;
    obj.timeFrom = coinsGroup.second.first;
    obj.timeTo = coinsGroup.second.second;
    return obj;
}

@end
