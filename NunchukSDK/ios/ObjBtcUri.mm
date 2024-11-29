//
//  ObjBtcUri.m
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 09/09/2022.
//

#import <Foundation/Foundation.h>
#import "ObjBtcUri.h"
#import "extensions/ObjBtcUri+Extension.h"
#include <nunchuk.h>

@implementation ObjBtcUri
-(instancetype)initWithBTCUri:(BtcUri)btcUri {
    ObjBtcUri *uri = [[ObjBtcUri alloc] init];
    uri.address = [NSString stringWithUTF8String: btcUri.address.c_str()];
    uri.amount = btcUri.amount;
    uri.message = [NSString stringWithUTF8String: btcUri.message.c_str()];
    uri.label = [NSString stringWithUTF8String: btcUri.label.c_str()];
    NSMutableDictionary<NSString*, NSString*> *map = [NSMutableDictionary new];
    for (auto const& other: btcUri.others) {
        NSString *key = [NSString stringWithUTF8String:other.first.c_str()];
        NSString *value = [NSString stringWithUTF8String:other.second.c_str()];
        map[key] = value;
    }
    uri.others = map;
    return uri;
}
@end
