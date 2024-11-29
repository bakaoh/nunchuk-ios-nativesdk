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
    return objOutput;
}

- (UnspentOutput)convertToC {
    UnspentOutput objInC;
    objInC.set_address([self.address UTF8String]);
    objInC.set_amount(self.amount);
    objInC.set_memo([self.memo UTF8String]);
    objInC.set_txid([self.txId UTF8String]);
    objInC.set_vout(self.vOut);
    objInC.set_height(self.height);
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

@end
