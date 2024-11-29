//
//  ObjTapsignerStatus.m
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 04/07/2022.
//

#import "ObjTapsignerStatus.h"
#import <extensions/ObjTapsignerStatusLibrary.h>

@implementation ObjTapsignerStatus
-(instancetype)initWithTapsignerStatus:(TapsignerStatus *)tapsignerStatus {
    ObjTapsignerStatus *status = [[ObjTapsignerStatus alloc] init];
    status.cardIdent = [NSString stringWithUTF8String:tapsignerStatus->get_card_ident().c_str()];
    status.currentDerivation = [NSString stringWithUTF8String:tapsignerStatus->get_current_derivation().c_str()];
    status.version = [NSString stringWithUTF8String:tapsignerStatus->get_version().c_str()];
    status.masterSignerId = [NSString stringWithUTF8String:tapsignerStatus->get_master_signer_id().c_str()];
    status.backupData = [[NSData alloc] initWithBytes:tapsignerStatus->get_backup_data().data() length:sizeof(unsigned char) * tapsignerStatus->get_backup_data().size()];
    status.birthHeight = tapsignerStatus->get_birth_height();
    status.numberOfBackup = tapsignerStatus->get_number_of_backup();
    status.authDelay = tapsignerStatus->get_auth_delay();
    status.isTestnet = tapsignerStatus->is_testnet();
    status.isMasterSigner = tapsignerStatus->is_master_signer();
    status.needSetup = tapsignerStatus->need_setup();
    return status;
}
@end
