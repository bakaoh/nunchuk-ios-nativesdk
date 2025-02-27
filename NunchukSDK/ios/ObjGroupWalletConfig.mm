//
//  ObjGroupMessage.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjGroupWalletConfig.h"
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjGroupWalletConfig {
}

- (instancetype _Nullable)initWithGroupWalletConfig:(GroupWalletConfig *_Nullable)config {
    ObjGroupWalletConfig *obj = [ObjGroupWalletConfig new];
    obj.chatRetentionDays = config->get_chat_retention_days();
    return obj;
}

@end
