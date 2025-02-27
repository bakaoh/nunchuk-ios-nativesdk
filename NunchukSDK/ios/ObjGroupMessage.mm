//
//  ObjGroupMessage.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjGroupMessage.h"
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjGroupMessage {
}

- (instancetype _Nullable)initWithGroupMessage:(GroupMessage *_Nullable)groupMessage {
    ObjGroupMessage *obj = [ObjGroupMessage new];
    obj.messageId = [NSString stringWithUTF8String:groupMessage->get_id().c_str()];
    obj.walletId = [NSString stringWithUTF8String:groupMessage->get_wallet_id().c_str()];
    obj.senderId = [NSString stringWithUTF8String:groupMessage->get_sender().c_str()];
    obj.content = [NSString stringWithUTF8String:groupMessage->get_content().c_str()];
    obj.signerId = [NSString stringWithUTF8String:groupMessage->get_signer().c_str()];
    obj.timestamp = groupMessage->get_ts();
    return obj;
}

@end
