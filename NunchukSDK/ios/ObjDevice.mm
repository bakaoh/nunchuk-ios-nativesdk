//
//  ObjDevice.m
//  nunchukSDK
//
//  Created by congtung private on 02/03/2021.
//

#import <Foundation/Foundation.h>
#include "ObjDevice.h"
#include <nunchuk.h>
using namespace nunchuk;

@implementation ObjDevice {
}
- (instancetype) initWithType: (NSString * _Nonnull) type : (NSString * _Nonnull) path :
    (NSString * _Nonnull) model : (NSString* _Nonnull) masterFingerPrint : (bool) isConnected :
    (bool) needsPassPhraseSent : (bool) needsPinSent : (bool) initialized isTapsigner:(BOOL)isTapsigner {
    ObjDevice * device = [[ObjDevice alloc] init];
    device->_type = type;
    device->_path = path;
    device->_needsPassPhraseSent = needsPassPhraseSent;
    device->_model = model;
    device->_masterFingerPrint = masterFingerPrint;
    device->_isConnected = isConnected;
    device->_needsPinSent = needsPinSent;
    device->_initialized = initialized;
    device->_isTapsigner = isTapsigner;
    return device;
}

- (instancetype) initWithDevice: (Device) device {
    NSString * type = [NSString stringWithUTF8String:device.get_type().c_str()];
    NSString * path = [NSString stringWithUTF8String:device.get_path().c_str()];
    NSString * model = [NSString stringWithUTF8String:device.get_model().c_str()];
    NSString * fingerPrint = [NSString stringWithUTF8String:device.get_master_fingerprint().c_str()];
    bool needPassPhrase = device.needs_pass_phrase_sent();
    bool connected = device.connected();
    bool needPinSent = device.needs_pin_sent();
    bool initialized = device.initialized();
    bool isTapsigner = device.is_tapsigner();
    return [[ObjDevice alloc] initWithType:type :path :model :fingerPrint :connected :needPassPhrase :needPinSent :initialized isTapsigner:isTapsigner];
}

@end
