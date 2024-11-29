//
//  ObjRoomTransaction.h
//  nunchukSDK
//
//  Created by Ha Nguyen Duc on 2021/10/05.
//

#ifndef ObjRoomTransaction_h
#define ObjRoomTransaction_h

#import <Foundation/Foundation.h>
#import "ObjTransaction.h"

@interface ObjRoomTransaction : NSObject
@property (nonatomic, strong) NSString *roomId;
@property (nonatomic, strong) NSString *txId;
@property (nonatomic, strong) NSString *walletId;
@property (nonatomic, strong) NSString *initializeEventId;
@property (nonatomic, strong) NSArray<NSString *> *signEventIds;
@property (nonatomic, strong) NSArray<NSString *> *rejectEventIds;
@property (nonatomic, strong) NSString *broadcastEventId;
@property (nonatomic, strong) NSString *cancelEventId;
@property (nonatomic, strong) NSString *readyEventId;
@property (nonatomic, strong) ObjTransaction *tx;
@end
#endif /* ObjRoomTransaction_h */
