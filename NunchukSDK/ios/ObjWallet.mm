//
//  ObjWallet.m
//  nunchukSDK
//
//  Created by congtung private on 02/03/2021.
//

#import <Foundation/Foundation.h>
#import "ObjWallet.h"
#import "ObjSingleSigner.h"
#import "NunchukImp.h"
#import "NunchukBridge.h"
#import "ObjMasterSigner.h"
#import "extensions/ObjSingleSignerLibrary.h"
#import "extensions/ObjMasterSignerLibrary.h"
#include <nunchuk.h>
using namespace nunchuk;

@implementation ObjWallet {
}
- (instancetype) initWithName: (NSString * _Nonnull) walletId  : (NSString * _Nonnull) walletName : (NSString * _Nonnull) desc :
    (NSString * _Nonnull) addressType : (NSDate* _Nonnull) createdAt : (NSString *) messageToSign : (int) m : (int) n : (int) gapLimit {
    ObjWallet * wallet = [[ObjWallet alloc] init];
    
    wallet->_walletName = walletName;
    wallet->_desc = desc;
    wallet->_createdAt = createdAt;
    wallet->_messageToSign = messageToSign;
    wallet->_m = m;
    wallet->_n = n;
    wallet->_walletId = walletId;
    wallet->_gapLimit = gapLimit;
    wallet->_isNeedBackup = NO;
    return wallet;
}

- (instancetype _Nonnull )initWithWallet:(Wallet *_Nullable)wallet nunchukManager:(NunchukManager *)nunchukManager {
    ObjWallet * objWallet = [[ObjWallet alloc] init];
    NSString* addressType = @"NESTED_SEGWIT";
    switch (wallet->get_address_type()) {
        case AddressType::LEGACY:
            addressType = @"LEGACY";
            break;
        case AddressType::NATIVE_SEGWIT:
            addressType = @"NATIVE_SEGWIT";
            break;
        case AddressType::NESTED_SEGWIT:
            addressType = @"NESTED_SEGWIT";
            break;
        case AddressType::TAPROOT:
            addressType = @"TAPROOT";
            break;
        case AddressType::ANY:
            addressType = @"ANY";
            break;
    }
    objWallet.signers = [[NSMutableArray alloc] init];
    for (auto signer : wallet->get_signers()) {
        ObjSingleSigner * remoteSigner = [[ObjSingleSigner alloc] initWithSigner:&signer];
        [objWallet.signers addObject:remoteSigner];
    }
    
    objWallet.addressType = addressType;
    int64_t balance = wallet->get_unconfirmed_balance();
    objWallet.balance = balance > 0 ? balance : 0;
    objWallet.walletId = [NSString stringWithUTF8String:wallet->get_id().c_str()];
    objWallet.createdAt = [[NSDate alloc] initWithTimeIntervalSince1970:wallet->get_create_date()];
    objWallet.desc = [NSString stringWithUTF8String:wallet->get_description().c_str()];
    objWallet.messageToSign = [NSString stringWithUTF8String:wallet->get_name().c_str()];
    objWallet.walletName =  [NSString stringWithUTF8String:wallet->get_name().c_str()];
    objWallet.m = wallet->get_m();
    objWallet.n = wallet->get_n();
    objWallet.isEscrow = wallet->is_escrow();
    objWallet.type = [self walletTypeStringFrom:wallet->get_wallet_type()];
    objWallet.gapLimit = wallet->get_gap_limit();
    objWallet.isNeedBackup = wallet->need_backup();
    
    return objWallet;
}

- (NSString *)walletTypeStringFrom:(WalletType)walletType {
    NSString *type = @"SINGLE_SIG";
    if (walletType == WalletType::SINGLE_SIG) {
        type = @"SINGLE_SIG";
    } else if (walletType == WalletType::ESCROW) {
        type = @"ESCROW";
    } else if (walletType == WalletType::MULTI_SIG) {
        type = @"MULTI_SIG";
    }
    return type;
}

@end

