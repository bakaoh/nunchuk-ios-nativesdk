//
//  ObjMasterSigner.m
//  nunchukSDK
//
//  Created by congtung private on 03/05/2021.
//

#import <Foundation/Foundation.h>
#import "ObjMasterSigner.h"
#include <nunchuk.h>
#import <extensions/ObjDeviceLibrary.h>
#include "utils/enumconverter.hpp"

using namespace nunchuk;
@implementation ObjMasterSigner {
}
- (instancetype _Nonnull) initWithName: (NSString *)signerName signerId: (NSString *)signerId device: (ObjDevice *)device lastTimeHealthCheck: (bool)lastTimeHealthCheck isSoftware: (bool)isSoftware signerType: (SignerType)signerType inheritable: (BOOL)inheritable tags:(NSArray *)tags isVisible:(BOOL)isVisible needBackup:(BOOL)needBackup {
    ObjMasterSigner * signer = [[ObjMasterSigner alloc] init];
    signer.signerName = signerName;
    signer.signerId = signerId;
    signer.device = device;
    signer.isSoftware = isSoftware;
    signer.lastTimeHealthCheck = lastTimeHealthCheck;
    signer.signerType = [self parseSignerType:signerType];
    signer.inheritable = inheritable;
    signer.tags = tags;
    signer.isVisible = isVisible;
    signer.needBackup = needBackup;
    return signer;
}

- (instancetype _Nonnull) initWithMasterSigner: (MasterSigner*_Nullable) masterSigner {
    NSString * name = [NSString stringWithUTF8String:masterSigner->get_name().c_str()];
    NSString * signerId = [NSString stringWithUTF8String:masterSigner->get_id().c_str()];
    bool isSoftware = masterSigner->is_software();
    bool lastTimeHealthCheck = masterSigner->get_last_health_check();
    ObjDevice * device =  [[ObjDevice alloc] initWithDevice:masterSigner->get_device()];
    auto signerTags = masterSigner->get_tags();
    BOOL inheritable = std::find(signerTags.begin(), signerTags.end(), SignerTag::INHERITANCE) != signerTags.end();
    NSMutableArray *tags = [NSMutableArray array];
    for (auto &tag : signerTags) {
        [tags addObject:[NSString stringWithUTF8String:SignerTagToStr(tag).c_str()]];
    }
    BOOL isVisible = masterSigner->is_visible();
    BOOL needBackup = masterSigner->need_backup();
    return [[ObjMasterSigner alloc] initWithName:name signerId:signerId device:device lastTimeHealthCheck:lastTimeHealthCheck isSoftware:isSoftware signerType:masterSigner->get_type() inheritable:inheritable tags:tags isVisible:isVisible needBackup:needBackup];
}

- (ObjCSignerType)parseSignerType:(SignerType)signerType {
    switch (signerType) {
        case nunchuk::SignerType::HARDWARE:
            return HARDWARE;
        case nunchuk::SignerType::SOFTWARE:
            return SOFTWARE;
        case nunchuk::SignerType::AIRGAP:
            return AIRGAP;
        case nunchuk::SignerType::FOREIGN_SOFTWARE:
            return FOREIGN_SOFTWARE;
        case nunchuk::SignerType::NFC:
            return NFC;
        case nunchuk::SignerType::COLDCARD_NFC:
            return ColdCardNFC;
        case nunchuk::SignerType::PORTAL_NFC:
            return PortalNFC;
        case nunchuk::SignerType::UNKNOWN:
            return UNKNOWN_SignerType;
        case nunchuk::SignerType::SERVER:
            return SERVER;
    }
}
@end
