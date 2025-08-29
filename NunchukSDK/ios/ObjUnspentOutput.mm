//
//  UnspentOutput.m
//  nunchukSDK
//
//  Created by congtung private on 08/06/2021.
//

#import <Foundation/Foundation.h>
#import "ObjUnspentOutput.h"
#import <extensions/ObjUnspentOutputLibrary.h>
#import "ObjTransaction.h"
#import <extensions/ObjTransactionLibrary.h>
#import "ObjTimeLock.h"

@implementation ObjUnspentOutput

- (instancetype)initWithUnspentOutput:(UnspentOutput *)output {
    ObjUnspentOutput *objOutput = [[ObjUnspentOutput alloc] init];
    objOutput.address = [NSString stringWithUTF8String:output->get_address().c_str()];
    int64_t amount = output->get_amount();
    objOutput.amount = amount > 0 ? amount : 0;
    objOutput.memo = [NSString stringWithUTF8String:output->get_memo().c_str()];
    objOutput.txId = [NSString stringWithUTF8String:output->get_txid().c_str()];
    objOutput.vOut = output->get_vout();
    objOutput.height = output->get_height();
    objOutput.isChange = output->is_change();
    objOutput.isLocked = output->is_locked();
    objOutput.blockTime = output->get_blocktime();
    objOutput.scheduledTime = output->get_schedule_time();
    objOutput.status = [self getCoinStats:output->get_status()];
    std::vector<int64_t> timelocksC = output->get_timelocks();
    NSMutableArray *timelockArray = [[NSMutableArray alloc] initWithCapacity:timelocksC.size()];
    for (int64_t value : timelocksC) {
        [timelockArray addObject:[NSNumber numberWithLongLong:value]];
    }
    objOutput.timelocks = [NSArray arrayWithArray:timelockArray];
    std::vector<int> tagsC = output->get_tags();
    NSMutableArray *tagArray = [[NSMutableArray alloc] initWithCapacity:tagsC.size()];
    for (int value : tagsC) {
        [tagArray addObject:[NSNumber numberWithInt:value]];
    }
    objOutput.tags = [NSArray arrayWithArray:tagArray];
    std::vector<int> collectionsC = output->get_collections();
    NSMutableArray *collectionArray = [[NSMutableArray alloc] initWithCapacity:collectionsC.size()];
    for (int value : collectionsC) {
        [collectionArray addObject:[NSNumber numberWithInt:value]];
    }
    objOutput.collections = [NSArray arrayWithArray:collectionArray];
    objOutput.timeLockBased = [self getTimeLockBased:output->get_lock_based()];
    return objOutput;
}

- (UnspentOutput)convertToC {
    UnspentOutput objInC;
    objInC.set_txid([self.txId UTF8String]);
    objInC.set_address([self.address UTF8String]);
    objInC.set_amount(self.amount);
    objInC.set_memo([self.memo UTF8String]);
    objInC.set_txid([self.txId UTF8String]);
    objInC.set_vout(self.vOut);
    objInC.set_height(self.height);
    objInC.set_change(self.isChange);
    objInC.set_locked(self.isLocked);
    objInC.set_blocktime(self.blockTime);
    objInC.set_schedule_time(self.scheduledTime);
    objInC.set_status([self getStatus:self.status]);
    std::vector<int64_t> timelocksC;
    for (NSNumber *value in self.timelocks) {
        timelocksC.push_back([value longLongValue]);
    }
    objInC.set_timelocks(timelocksC);
    std::vector<int> tagsC;
    for (NSNumber *value in self.tags) {
        tagsC.push_back([value intValue]);
    }
    objInC.set_tags(tagsC);
    std::vector<int> collectionsC;
    for (NSNumber *value in self.collections) {
        collectionsC.push_back([value intValue]);
    }
    objInC.set_collections(collectionsC);
    
    return objInC;
}

- (CoinStatusEnum)getCoinStats:(CoinStatus)status {
    switch (status) {
        case nunchuk::CoinStatus::INCOMING_PENDING_CONFIRMATION:
            return COIN_STATUS_INCOMING_PENDING_CONFIRMATION;
        case nunchuk::CoinStatus::CONFIRMED:
            return COIN_STATUS_CONFIRMED;
        case nunchuk::CoinStatus::OUTGOING_PENDING_SIGNATURES:
            return COIN_STATUS_OUTGOING_PENDING_SIGNATURES;
        case nunchuk::CoinStatus::OUTGOING_PENDING_BROADCAST:
            return COIN_STATUS_OUTGOING_PENDING_BROADCAST;
        case nunchuk::CoinStatus::OUTGOING_PENDING_CONFIRMATION:
            return COIN_STATUS_OUTGOING_PENDING_CONFIRMATION;
        case nunchuk::CoinStatus::SPENT:
            return COIN_STATUS_SPENT;
        default:
            return COIN_STATUS_UNKNOWN;
    }
}

- (CoinStatus)getStatus:(CoinStatusEnum)status {
    switch (self.status) {
        case COIN_STATUS_INCOMING_PENDING_CONFIRMATION:
            return nunchuk::CoinStatus::INCOMING_PENDING_CONFIRMATION;
        case COIN_STATUS_CONFIRMED:
            return nunchuk::CoinStatus::CONFIRMED;
        case COIN_STATUS_OUTGOING_PENDING_SIGNATURES:
            return nunchuk::CoinStatus::OUTGOING_PENDING_SIGNATURES;
        case COIN_STATUS_OUTGOING_PENDING_BROADCAST:
            return nunchuk::CoinStatus::OUTGOING_PENDING_BROADCAST;
        case COIN_STATUS_OUTGOING_PENDING_CONFIRMATION:
            return nunchuk::CoinStatus::OUTGOING_PENDING_CONFIRMATION;
        case COIN_STATUS_SPENT:
            return nunchuk::CoinStatus::SPENT;
        default:
            return nunchuk::CoinStatus::SPENT;
    }
}

- (TimeLockBased)getTimeLockBased:(Timelock::Based)based {
    switch (based) {
        case Timelock::Based::NONE:
            return NONE;
        case Timelock::Based::TIME_LOCK:
            return TIME_LOCK;
        case Timelock::Based::HEIGHT_LOCK:
            return HEIGHT_LOCK;
    }
}

@end

void set_timelocks(std::vector<int64_t> value);
