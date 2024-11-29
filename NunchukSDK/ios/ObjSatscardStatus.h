//
//  ObjSatscardStatus.h
//  nunchukWalletSDK
//
//  Created by Hà Nguyễn Đức on 31/07/2022.
//

#import <Foundation/Foundation.h>
#import "ObjSatscardSlot.h"

@interface ObjSatscardStatus : NSObject
@property (nonatomic, strong) NSString *cardIdent;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, assign) NSInteger birthHeight;
@property (nonatomic, assign) NSInteger authDelay;
@property (nonatomic, assign) NSInteger activeSlotIndex;
@property (nonatomic, assign) NSInteger numberOfSlots;
@property (nonatomic, assign) BOOL isTestnet;
@property (nonatomic, assign) BOOL isUsedUp;
@property (nonatomic, assign) BOOL needSetup;
@property (nonatomic, strong) NSArray<ObjSatscardSlot*> *slots;
@property (nonatomic, strong) ObjSatscardSlot* activeSlot;
@end
