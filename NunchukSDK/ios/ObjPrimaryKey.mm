//
//  ObjPrimaryKey.m
//  nunchukSDK
//
//  Created by Thai Nguyen on 6/2/22.
//

#import <Foundation/Foundation.h>
#import "ObjPrimaryKey.h"
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjPrimaryKey

- (instancetype)initWithPrimaryKey:(PrimaryKey *)key {
    ObjPrimaryKey *primaryKey = [ObjPrimaryKey new];
    primaryKey.name = [NSString stringWithUTF8String: key->get_name().c_str()];
    primaryKey.masterFingerprint = [NSString stringWithUTF8String: key->get_master_fingerprint().c_str()];
    primaryKey.account = [NSString stringWithUTF8String: key->get_account().c_str()];
    primaryKey.address = [NSString stringWithUTF8String: key->get_address().c_str()];
    primaryKey.decoyPIN = [NSString stringWithUTF8String: key->get_decoy_pin().c_str()];
    return primaryKey;
}

@end
