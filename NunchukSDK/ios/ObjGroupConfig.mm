//
//  ObjGroupConfig.m
//  nunchukSDK
//
//  Created by macbook on 11/1/25.
//

#import <Foundation/Foundation.h>
#import "ObjGroupConfig.h"
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjGroupConfig

- (instancetype)initWithGroupConfig:(GroupConfig *)config {
    self = [super init];
    if (self) {
        self.total = config->get_total();
        self.remain = config->get_remain();
        NSMutableDictionary *_addressKeyLimits = [[NSMutableDictionary alloc] init];
        
        // Map address type limits
        [_addressKeyLimits setObject:@(config->get_max_keys(AddressType::LEGACY)) forKey:@"LEGACY"];
        [_addressKeyLimits setObject:@(config->get_max_keys(AddressType::NATIVE_SEGWIT)) forKey:@"NATIVE_SEGWIT"];
        [_addressKeyLimits setObject:@(config->get_max_keys(AddressType::NESTED_SEGWIT)) forKey:@"NESTED_SEGWIT"];
        [_addressKeyLimits setObject:@(config->get_max_keys(AddressType::TAPROOT)) forKey:@"TAPROOT"];
        self.addressKeyLimits = [[NSDictionary alloc] initWithDictionary:_addressKeyLimits];
        
        NSMutableArray *options = [NSMutableArray new];
        for (auto option: config->get_retention_days_options()) {
            [options addObject:[NSNumber numberWithInt:option]];
        }
        self.retentionDaysOptions = [NSArray arrayWithArray:options];
    }
    return self;
}

@end
