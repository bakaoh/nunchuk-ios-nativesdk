//
//  ObjWalletData.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjWalletData.h"

@implementation ObjWalletData {
}

- (instancetype _Nullable)initWithWallet:(ObjWallet *)wallet bsms:(NSString *)bsms firstAddress:(NSString *)firstAddress {
    ObjWalletData *obj = [ObjWalletData new];
    obj.wallet = wallet;
    obj.bsms = bsms;
    obj.firstAddress = firstAddress;
    return obj;
}

@end
