//
//  ObjRoomWallet.mm
//  nunchukSDK
//
//  Created by Ha Nguyen Duc on 2021/08/30.
//

#import <Foundation/Foundation.h>
#import "ObjRoomWallet.h"
#include <nunchukmatrix.h>
using namespace nunchuk;

@implementation ObjRoomWallet {
}
- (instancetype _Nullable)initWithRoomWallet: (RoomWallet *_Nullable) roomWallet {
    if (roomWallet == NULL) { return NULL;}
    ObjRoomWallet *objRoomWallet = [[ObjRoomWallet alloc] init];
    objRoomWallet.walletId = [NSString stringWithUTF8String: roomWallet->get_wallet_id().c_str()];
    objRoomWallet.initializeEventId = [NSString stringWithUTF8String: roomWallet->get_init_event_id().c_str()];
    objRoomWallet.finalizeEventId = [NSString stringWithUTF8String: roomWallet->get_finalize_event_id().c_str()];
    objRoomWallet.readyEventId = [NSString stringWithUTF8String: roomWallet->get_ready_event_id().c_str()];
    objRoomWallet.cancelEventId = [NSString stringWithUTF8String: roomWallet->get_cancel_event_id().c_str()];
    objRoomWallet.deleteEventId = [NSString stringWithUTF8String: roomWallet->get_delete_event_id().c_str()];
    NSMutableArray *joinEventIds = [[NSMutableArray alloc] init];
    for (auto& eventId : roomWallet->get_join_event_ids()) {
        [joinEventIds addObject:[NSString stringWithUTF8String:eventId.c_str()]];
    }
    objRoomWallet.joinEventIds = joinEventIds;
    
    NSMutableArray *leaveEventIds = [[NSMutableArray alloc] init];
    for (auto& eventId : roomWallet->get_leave_event_ids()) {
        [leaveEventIds addObject:[NSString stringWithUTF8String:eventId.c_str()]];
    }
    objRoomWallet.leaveEventIds = leaveEventIds;
    
    objRoomWallet.jsonContent = [NSString stringWithUTF8String: roomWallet->get_json_content().c_str()];
    if ([objRoomWallet.cancelEventId length] != 0) {
        objRoomWallet.state = CANCEL;
    } else if ([objRoomWallet.deleteEventId length] != 0) {
        objRoomWallet.state = CANCEL;
    } else if ([objRoomWallet.finalizeEventId length] != 0) {
        objRoomWallet.state = FINALIZE;
    } else {
        objRoomWallet.state = PENDING;
    }
    
    objRoomWallet.roomId = [NSString stringWithUTF8String: roomWallet->get_room_id().c_str()];
    return objRoomWallet;
}
@end
