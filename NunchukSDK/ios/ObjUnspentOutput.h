//
//  UnspentOutput.h
//  nunchukWalletSDK
//
//  Created by congtung private on 08/06/2021.
//

#ifndef ObjUnspentOutput_h
#define ObjUnspentOutput_h

#import "ObjTimeLock.h"

typedef enum CoinStatusEnum {
    COIN_STATUS_INCOMING_PENDING_CONFIRMATION,
    COIN_STATUS_CONFIRMED,
    COIN_STATUS_OUTGOING_PENDING_SIGNATURES,
    COIN_STATUS_OUTGOING_PENDING_BROADCAST,
    COIN_STATUS_OUTGOING_PENDING_CONFIRMATION,
    COIN_STATUS_SPENT,
    COIN_STATUS_UNKNOWN
} CoinStatusEnum;

@interface ObjUnspentOutput: NSObject
@property (nonatomic, strong, nullable) NSString* txId;
@property (nonatomic, assign) long vOut;
@property (nonatomic, assign) long amount;
@property (nonatomic, assign) long height;
@property (nonatomic, strong, nullable) NSString* memo;
@property (nonatomic, strong, nullable) NSString* address;
@property (nonatomic, assign) BOOL isChange;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) int64_t blockTime;
@property (nonatomic, assign) int64_t scheduledTime;
@property (nonatomic, assign) CoinStatusEnum status;
@property (nonatomic, strong, nullable) NSArray<NSNumber*>* timelocks;
@property (nonatomic, assign) TimeLockBased timeLockBased;
@property (nonatomic, strong, nullable) NSArray<NSNumber*>* tag;
@property (nonatomic, strong, nullable) NSArray<NSNumber*>* collections;

@end
#endif /* UnspentOutput_h */
