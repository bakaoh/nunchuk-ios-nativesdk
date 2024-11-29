//
//  ObjSatscardStatus.m
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 31/07/2022.
//

#import <Foundation/Foundation.h>
#import "ObjSatscardStatus.h"
#import <extensions/ObjSatscardStatus+Extension.h>
#import <extensions/ObjSatscardSlotLibrary.h>

@implementation ObjSatscardStatus
- (instancetype)initWithSatscardStatus:(SatscardStatus *)satscardStatus {
    ObjSatscardStatus *status = [[ObjSatscardStatus alloc] init];
    status.cardIdent = [NSString stringWithUTF8String:satscardStatus->get_card_ident().c_str()];
    status.version = [NSString stringWithUTF8String:satscardStatus->get_version().c_str()];
    status.birthHeight = satscardStatus->get_birth_height();
    status.authDelay = satscardStatus->get_auth_delay();
    status.activeSlotIndex = satscardStatus->get_active_slot_index();
    status.numberOfSlots = satscardStatus->get_number_of_slots();
    status.isTestnet = satscardStatus->is_testnet();
    status.isUsedUp = satscardStatus->is_used_up();
    status.needSetup = satscardStatus->need_setup();
    
    NSMutableArray *arraySlots = [NSMutableArray new];
    auto cSlots = satscardStatus->get_slots();
    for (auto& cSlot: cSlots) {
        [arraySlots addObject:[[ObjSatscardSlot alloc] initWithSatscardSlot:&cSlot]];
    }
    status.slots = arraySlots;
    auto cActiveSlot = satscardStatus->get_active_slot();
    status.activeSlot = [[ObjSatscardSlot alloc] initWithSatscardSlot:&cActiveSlot];
    return status;
}
@end
