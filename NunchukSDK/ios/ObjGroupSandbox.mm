//
//  ObjGroupSandbox.m
//  nunchukSDK
//
//  Created by Hung Nguyen on 1/14/25.
//

#import <Foundation/Foundation.h>
#import "ObjGroupSandbox.h"
#import "ObjSingleSigner.h"
#import <extensions/ObjSingleSignerLibrary.h>
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjGroupSandbox

- (instancetype)initWithGroupSandbox:(GroupSandbox *)groupSandbox {
    self = [super init];
    if (self) {
        self.groupId = [NSString stringWithUTF8String:groupSandbox->get_id().c_str()];
        self.name = [NSString stringWithUTF8String:groupSandbox->get_name().c_str()];
        self.walletId = [NSString stringWithUTF8String:groupSandbox->get_wallet_id().c_str()];
        self.pubkey = [NSString stringWithUTF8String:groupSandbox->get_pubkey().c_str()];
        self.url = [NSString stringWithUTF8String:groupSandbox->get_url().c_str()];
        self.m = groupSandbox->get_m();
        self.n = groupSandbox->get_n();
        
        // Map address type
        switch (groupSandbox->get_address_type()) {
            case AddressType::LEGACY:
                self.addressType = @"LEGACY";
                break;
            case AddressType::NATIVE_SEGWIT:
                self.addressType = @"NATIVE_SEGWIT";
                break;
            case AddressType::NESTED_SEGWIT:
                self.addressType = @"NESTED_SEGWIT";
                break;
            case AddressType::TAPROOT:
                self.addressType = @"TAPROOT";
                break;
            default:
                self.addressType = @"ANY";
                break;
        }
        
        // Map signers
        const auto& signers = groupSandbox->get_signers();
        NSMutableArray<ObjSingleSigner *> *array = [[NSMutableArray alloc] initWithCapacity:signers.size()];
        for(unsigned i = 0; i < signers.size(); i++) {
            auto signer = signers.at(i);
            ObjSingleSigner * objSigner = [[ObjSingleSigner alloc] initWithSigner: &signer];
            [array addObject: objSigner];
        }
        self.signers = array;
        
        // Map ephemeral keys
        NSMutableArray *keys = [[NSMutableArray alloc] init];
        for (const auto& key : groupSandbox->get_ephemeral_keys()) {
            [keys addObject:[NSString stringWithUTF8String:key.c_str()]];
        }
        self.ephemeralKeys = keys;
        
        self.isFinalized = groupSandbox->is_finalized();

        // Add occupied slots mapping
        NSMutableDictionary *slots = [NSMutableDictionary new];
        const auto& occupied = groupSandbox->get_occupied();
        for (const auto& pair : occupied) {
            NSNumber *key = @(pair.first);  // slot index
            auto value = pair.second;  // std::pair<time_t, std::string>
            NSArray *slotInfo = @[@(value.first), [NSString stringWithUTF8String:value.second.c_str()]];
            [slots setObject:slotInfo forKey:key];
        }
        self.occupiedSlots = slots;
    }
    return self;
}

@end
