//
//  ObjTransaction.m
//  nunchukSDK
//
//  Created by congtung private on 13/05/2021.
//

#import <Foundation/Foundation.h>
#import "ObjTransaction.h"
#include <nunchuk.h>
#import <extensions/ObjSingleSignerLibrary.h>

using namespace nunchuk;

@implementation ObjTransaction {
}
- (instancetype _Nonnull ) initWithTransaction: (Transaction*_Nullable) transaction {
    ObjTransaction * obj = [[ObjTransaction alloc] init];
    obj.blockTime = transaction->get_blocktime();
    obj.changeIndex = transaction->get_change_index();
   
    obj.transactionId = [NSString stringWithUTF8String:transaction->get_txid().c_str()];
    obj.height = transaction->get_height();
    NSMutableArray * objInput = [[NSMutableArray alloc] init];
    
    for(auto& input: transaction->get_inputs()) {
        ObjTransactionInput *txInput = [[ObjTransactionInput alloc] initWithTxId:[[NSString alloc] initWithUTF8String:input.txid.c_str()] vout:input.vout nSequence:input.nSequence];
        [objInput addObject:txInput];
    }
    obj.input = [objInput copy];
    NSMutableArray * objOutput = [[NSMutableArray alloc] init];
    
    for(auto& output: transaction->get_outputs()) {
        StringIntPair * pair = [[StringIntPair alloc] init];
        pair.key = [[NSString alloc] initWithUTF8String:output.first.c_str()];
        pair.value = output.second;
        [objOutput addObject:pair];
    }
    obj.output = [objOutput copy];
    obj.userOutput = [[NSArray alloc] init];
    NSMutableArray * userOutput = [[NSMutableArray alloc] init];
    for(auto& output: transaction->get_user_outputs()) {
        StringIntPair * pair = [[StringIntPair alloc] init];
        pair.key = [[NSString alloc] initWithUTF8String:output.first.c_str()];
        pair.value = output.second;
        [userOutput addObject:pair];
    }
    obj.userOutput = [userOutput copy];
    NSMutableArray * receivedOutput = [[NSMutableArray alloc] init];
    for(auto& output: transaction->get_receive_outputs()) {
        StringIntPair * pair = [[StringIntPair alloc] init];
        pair.key = [[NSString alloc] initWithUTF8String:output.first.c_str()];
        pair.value = output.second;
        [receivedOutput addObject:pair];
    }
    obj.receivedOutput = [receivedOutput copy];
    obj.changeIndex = transaction->get_change_index();
    obj.m = transaction->get_m();
    NSMutableArray * signersArray = [[NSMutableArray alloc] init];
    for (auto const& signer : transaction->get_signers()) {
        StringIntPair * pair = [[StringIntPair alloc] init];
        pair.key = [NSString stringWithUTF8String:signer.first.c_str()];
        pair.value = signer.second == true ? 1 : 0;
        [signersArray addObject:pair];
    }
    obj.signers = [signersArray copy];
    obj.memo = [[NSString alloc] initWithUTF8String: transaction->get_memo().c_str()];
    obj.status = [ObjTransaction transactionStatusFrom:transaction->get_status()];
    obj.replacedId = [[NSString alloc] initWithUTF8String:transaction->get_replaced_by_txid().c_str()];
    int64_t fee = transaction->get_fee();
    obj.fee = fee > 0 ? fee : 0;
    int64_t feeRate = transaction->get_fee_rate();
    obj.feeRate = feeRate > 0 ? feeRate : 0;
    obj.subtractFeeFromAmount = transaction->subtract_fee_from_amount();
    obj.isReceived = transaction->is_receive();
    int64_t subAmount = transaction->get_sub_amount();
    obj.subAmount = subAmount > 0 ? subAmount : 0;
    obj.replaceTXid = [[NSString alloc] initWithUTF8String:transaction->get_replace_txid().c_str()];
    obj.psbt = [[NSString alloc] initWithUTF8String:transaction->get_psbt().c_str()];
    obj.vsize = transaction->get_vsize();
    obj.scheduleTime = transaction->get_schedule_time();
    
    if (![obj.status isEqualToString:@"PENDING_CONFIRMATION"] && ![obj.status isEqualToString:@"CONFIRMED"]) {
        NSMutableArray *signedArray = [[NSMutableArray alloc] init];
        for (auto signer : transaction->get_signed()) {
            ObjSingleSigner *signerObj = [[ObjSingleSigner alloc] initWithSigner:&signer];
            [signedArray addObject:signerObj];
        }
        obj.signedKeys = [NSArray arrayWithArray:signedArray];
    }
    return obj;
}

+ (NSString *)transactionStatusFrom:(TransactionStatus)status {
    NSString *txStatus = @"";
    switch (status) {
        case TransactionStatus::PENDING_SIGNATURES:
            txStatus = @"PENDING_SIGNATURES";
            break;
        case TransactionStatus::READY_TO_BROADCAST:
            txStatus = @"READY_TO_BROADCAST";
            break;
        case TransactionStatus::NETWORK_REJECTED:
            txStatus = @"NETWORK_REJECTED";
            break;
        case TransactionStatus::PENDING_CONFIRMATION:
            txStatus = @"PENDING_CONFIRMATION";
            break;
        case TransactionStatus::REPLACED:
            txStatus = @"REPLACED";
            break;
        case TransactionStatus::CONFIRMED:
            txStatus = @"CONFIRMED";
            break;
        case TransactionStatus::PENDING_NONCE:
            txStatus = @"PENDING_NONCE";
            break;
        default:
            break;
    }
    return txStatus;
}

@end

@implementation ObjTransactionInput {
}

- (instancetype _Nullable)initWithTxId:(NSString *_Nonnull)txId vout:(int64_t)vout nSequence:(int64_t)nSequence {
    ObjTransactionInput *input = [ObjTransactionInput new];
    input.txId = txId;
    input.vout = vout;
    input.nSequence = nSequence;
    return input;
}

@end
