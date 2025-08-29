//
//  ObjTimeLock.mm
//  nunchukSDK
//
//  Created by macbook on 11/1/25.
//

#import <Foundation/Foundation.h>
#import "ObjTimeLock.h"
#include <nunchuk.h>

using namespace nunchuk;

@implementation ObjTimeLock

- (instancetype)initWithTimelock:(Timelock *)timelock {
    self = [super init];
    if (self) {
        self.based = static_cast<int>(timelock->based());
        self.type = static_cast<int>(timelock->type());
        self.value = timelock->value();
        self.k = timelock->k();
    }
    return self;
}

@end 