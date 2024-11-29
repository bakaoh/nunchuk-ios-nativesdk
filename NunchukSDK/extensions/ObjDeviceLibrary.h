//
//  ObjDeviceLibrary.h
//  nunchukWalletSDK
//
//  Created by congtung private on 03/05/2021.
//

#ifndef ObjDeviceLibrary_h
#define ObjDeviceLibrary_h

#include <nunchuk.h>
using namespace  nunchuk;

@interface ObjDevice (Library)
- (instancetype) initWithDevice: (Device) device;
@end
#endif /* ObjDeviceLibrary_h */
