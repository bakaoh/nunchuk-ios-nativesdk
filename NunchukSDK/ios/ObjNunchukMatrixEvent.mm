//
//  StringIntPair.m
//  nunchukSDK
//
//  Created by congtung private on 13/05/2021.
//

#import <Foundation/Foundation.h>
#import "ObjNunchukMatrixEvent.h"
#include <nunchuk.h>
#include <nunchukmatrix.h>
#include <nunchukmatriximpl.h>

using namespace nunchuk;


@implementation ObjNunchukMatrixEvent
- (instancetype _Nonnull) initWithMatrixEvent: (NunchukMatrixEvent) event {
    ObjNunchukMatrixEvent * objEvent = [[ObjNunchukMatrixEvent alloc] init];
    objEvent.type = [NSString stringWithUTF8String:event.get_type().c_str()];
    objEvent.content = [NSString stringWithUTF8String:event.get_content().c_str()];
    objEvent.eventId = [NSString stringWithUTF8String:event.get_event_id().c_str()];
    objEvent.roomId = [NSString stringWithUTF8String:event.get_room_id().c_str()];
    objEvent.senderId = [NSString stringWithUTF8String:event.get_sender().c_str()];
    objEvent.timestamp = event.get_ts();
    return objEvent;
}
- (NunchukMatrixEvent) getNunchukEvent {
    NunchukMatrixEvent objEvent;
    objEvent.set_type([self.type UTF8String]);
    objEvent.set_content([self.content UTF8String]);
    objEvent.set_event_id([self.eventId UTF8String]);
    objEvent.set_room_id([self.roomId UTF8String]);
    objEvent.set_sender([self.senderId UTF8String]);
    objEvent.set_ts(self.timestamp);
    return objEvent;
}
@end
