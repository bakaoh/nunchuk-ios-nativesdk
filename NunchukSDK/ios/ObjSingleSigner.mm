//
//  ObjSingleSigner.m
//  nunchukSDK
//
//  Created by congtung private on 02/03/2021.
//

#import <Foundation/Foundation.h>
#import "ObjSingleSigner.h"
#include <nunchuk.h>
#import "ObjMasterSigner.h"
#include "utils/enumconverter.hpp"
#import "NunchukLibUlti.h"

using namespace nunchuk;
@implementation ObjSingleSigner {
}
- (instancetype)initWithName:(NSString * _Nonnull)name
                        xpub:(NSString * _Nonnull)xpub
                   bip32Path:(NSString * _Nonnull)bip32Path
               messageToSign:(NSString * _Nonnull)messageToSign
                   publicKey:(NSString * _Nonnull)publicKey
           masterFingerPrint:(NSString * _Nonnull)masterFingerPrint
                    signerId:(NSString * _Nonnull)signerId
                  descriptor:(NSString * _Nonnull)descriptor
           lastHealthCheckTS:(double)lastHealthCheckTS
                        type:(ObjCSignerType)type
             hasMasterSigner:(BOOL)hasMasterSigner
                        tags:(NSArray *)tags
                   isVisible:(BOOL)isVisible 
                   indexPath:(NSInteger)indexPath {
    ObjSingleSigner * signer = [[ObjSingleSigner alloc] init];
    signer->_signerName = name;
    signer->_bip32Path = bip32Path;
    signer->_messageToSign = messageToSign;
    signer->_xpub = xpub;
    signer->_signerId = signerId;
    signer->_publicKey = publicKey;
    signer->_masterFingerPrint = masterFingerPrint;
    signer->_descriptor = descriptor;
    signer->_lastHealthCheckTS = lastHealthCheckTS;
    signer->_type = type;
    signer->_hasMasterSigner = hasMasterSigner;
    signer.tags = tags;
    signer.isVisible = isVisible;
    signer.indexPath = indexPath;
    return signer;
}
- (instancetype _Nonnull ) initWithSigner: (SingleSigner*_Nullable) signer {
    NSString * name = [NSString stringWithUTF8String:signer->get_name().c_str()];
    NSString * xpub = [NSString stringWithUTF8String:signer->get_xpub().c_str()];
    NSString * bip32Path = [NSString stringWithUTF8String:signer->get_derivation_path().c_str()];
    NSString * message = [NSString stringWithUTF8String:signer->get_name().c_str()];
    NSString * publicKey = [NSString stringWithUTF8String:signer->get_public_key().c_str()];
    NSString * masterFingerPrint = [NSString stringWithUTF8String:signer->get_master_fingerprint().c_str()];
    NSString * masterId = [NSString stringWithUTF8String:signer->get_master_signer_id().c_str()];
    NSString *descriptor = [NSString stringWithUTF8String:signer->get_descriptor().c_str()];
    double time = signer->get_last_health_check();
    ObjCSignerType type = [self parseSignerType:signer->get_type()];
    NSMutableArray *tags = [NSMutableArray array];
    for (auto &tag : signer->get_tags()) {
        [tags addObject:[NSString stringWithUTF8String:SignerTagToStr(tag).c_str()]];
    }
    NSInteger indexPath = Utils::GetIndexFromPath(signer->get_derivation_path());
    ObjSingleSigner * objSigner = [[ObjSingleSigner alloc] initWithName:name
                                                                   xpub:xpub
                                                              bip32Path:bip32Path
                                                          messageToSign:message
                                                              publicKey:publicKey
                                                      masterFingerPrint:masterFingerPrint
                                                               signerId:masterId
                                                             descriptor:descriptor
                                                      lastHealthCheckTS:time
                                                                   type:type
                                                        hasMasterSigner:signer->has_master_signer()
                                                                   tags:tags
                                                              isVisible:signer->is_visible()
                                                              indexPath:indexPath];
    return objSigner;
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

- (BOOL)hasAirgapTypeTag {
    for (NSString * tag in _tags) {
        if ([[NunchukLibUlti shared] isAirgapTypeTag:tag]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasHardwareTypeTag {
    for (NSString * tag in _tags) {
        if ([[NunchukLibUlti shared] isHardwareTypeTag:tag]) {
            return YES;
        }
    }
    return NO;
}

@end
