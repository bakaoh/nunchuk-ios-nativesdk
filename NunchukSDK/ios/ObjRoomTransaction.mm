//
//  ObjRoomTransaction.m
//  nunchukSDK
//
//  Created by Ha Nguyen Duc on 2021/10/05.
//

#import "ObjRoomTransaction.h"
#include <nunchukmatrix.h>
#import <extensions/ObjTransactionLibrary.h>
using namespace nunchuk;

@implementation ObjRoomTransaction
- (instancetype _Nullable)initWithRoomTransaction: (RoomTransaction *_Nullable)roomTransaction {
    if (roomTransaction == NULL) { return NULL; }
    ObjRoomTransaction *objRoomTx = [[ObjRoomTransaction alloc] init];
    objRoomTx.roomId = [NSString stringWithUTF8String:roomTransaction->get_room_id().c_str()];
    objRoomTx.txId = [NSString stringWithUTF8String:roomTransaction->get_tx_id().c_str()];
    objRoomTx.walletId = [NSString stringWithUTF8String:roomTransaction->get_wallet_id().c_str()];
    objRoomTx.initializeEventId = [NSString stringWithUTF8String:roomTransaction->get_init_event_id().c_str()];
    NSMutableArray<NSString *> *signEventIds = [[NSMutableArray alloc] init];
    for (auto& signEventId : roomTransaction->get_sign_event_ids()) {
        [signEventIds addObject: [NSString stringWithUTF8String: signEventId.c_str()]];
    }
    objRoomTx.signEventIds = signEventIds;
    NSMutableArray<NSString *> *rejectEventIds = [[NSMutableArray alloc] init];
    for (auto& rejectEventId : roomTransaction->get_reject_event_ids()) {
        [rejectEventIds addObject: [NSString stringWithUTF8String: rejectEventId.c_str()]];
    }
    objRoomTx.rejectEventIds = rejectEventIds;
    objRoomTx.broadcastEventId = [NSString stringWithUTF8String:roomTransaction->get_broadcast_event_id().c_str()];
    objRoomTx.cancelEventId = [NSString stringWithUTF8String:roomTransaction->get_cancel_event_id().c_str()];
    objRoomTx.readyEventId = [NSString stringWithUTF8String:roomTransaction->get_ready_event_id().c_str()];
    auto tx = roomTransaction->get_tx();
    objRoomTx.tx = [[ObjTransaction alloc] initWithTransaction: &tx];
    return objRoomTx;
}
@end
