//
//  ObjCoinTag.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjSignMessage.h"

@implementation ObjSignMessage {
}

- (instancetype _Nullable)initWithAddress:(NSString *)address signature:(NSString *)signature {
    ObjSignMessage *obj = [ObjSignMessage new];
    obj.address = address;
    obj.signature = signature;
    return obj;
}

@end

