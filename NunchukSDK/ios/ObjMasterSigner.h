//
//  ObjMasterSigner.m
//  nunchukSDK
//
//  Created by congtung private on 03/05/2021.
//

#import <Foundation/Foundation.h>
#ifndef ObjMasterSigner_h
#define ObjMasterSigner_h
#include "ObjDevice.h"

typedef enum ObjCSignerType {
    HARDWARE,
    AIRGAP,
    SOFTWARE,
    FOREIGN_SOFTWARE,
    NFC,
    ColdCardNFC,
    PortalNFC,
    UNKNOWN_SignerType,
    SERVER
} ObjCSignerType;

@interface ObjMasterSigner : NSObject
@property(nonatomic, strong, nonnull) NSString* signerId;
@property(nonatomic, strong, nullable) NSString* signerName;
@property(nonatomic, strong, nullable) ObjDevice* device;
@property(nonatomic) long lastTimeHealthCheck;
@property(nonatomic) bool isSoftware;
@property(nonatomic) ObjCSignerType signerType;
@property(nonatomic) bool inheritable;
@property(nonatomic, strong, nonnull) NSArray *tags;
@property(nonatomic, assign) BOOL isVisible;

@end
#endif /* ObjMasterSigner_h */
