#import "NunchukImp.h"
#import "NunchukBridge.h"
#import <extensions/ObjSingleSignerLibrary.h>
#import <extensions/ObjMasterSignerLibrary.h>
#import <extensions/ObjTransactionLibrary.h>
#import <extensions/ObjWalletLibrary.h>
#import <extensions/ObjUnspentOutputLibrary.h>
#import <extensions/ObjNunchukMatrixEventLibrary.h>
#import <extensions/ObjRoomWalletLibrary.h>
#import <extensions/ObjRoomTransactionLibrary.h>
#import "ObjUnspentOutput.h"
#import <ios/ObjNunchukMatrixEvent.h>
#import "ObjDevice.h"
#include <nunchuk.h>
#include <string.h>
#import "ObjAppSettings.h"
#import <extensions/ObjAppSettings+Extension.h>
#include <nlohmann/json.hpp>
#include "tap_protocol/tap_protocol.h"
#import <extensions/ObjTapsignerStatusLibrary.h>
#include <utils/loguru.hpp>
#import <extensions/ObjSatscardStatus+Extension.h>
#import <extensions/ObjSatscardSlotLibrary.h>
#include "descriptor.h"
#include "utils/coldcard.hpp"
#import "ObjAssistedWallet.h"
#import "ObjKeyInfo.h"
#import "ObjTapSignerKeyInfo.h"
#import "ObjRemoteTransaction.h"
#include "utils/enumconverter.hpp"
#import "NunchukLibUlti.h"
#import "ObjCoinTag.h"
#import "ObjSignMessage.h"
#import "ObjCoinCollection.h"
#import <extensions/ObjCoinCollection+Extension.h>
#import <extensions/ObjCoinTag+Extension.h>
#import "ObjWalletData.h"
#import "ObjDraftRolloverTransaction.h"
#import "ObjBSMSData.h"
#import "ObjKeySetStatus.h"
#import <extensions/ObjKeySetStatus+Extension.h>
#import "ObjGroupMessage.h"
#import <extensions/ObjGroupMessage+Extension.h>
#import "ObjGroupConfig.h"
#import <extensions/ObjGroupConfig+Extension.h>
#import "ObjGroupWalletConfig.h"
#import <extensions/ObjGroupWalletConfig+Extension.h>
#import "ObjGroupSandbox.h"
#import <extensions/ObjGroupSandbox+Extension.h>
#import "ObjCoinGroup.h"
#import <extensions/ObjCoinGroup+Extension.h>

using namespace nunchuk;
using namespace tap_protocol;

@interface NunchukImp () <NFCTagReaderSessionDelegate>

// Work arouund to pass varibale to c++ lambra function
@property (nonatomic, retain) NSString *syncRoomId;
@property (nonatomic, strong) NFCTagReaderSession *session;
@end

@implementation NunchukImp {
    std::unique_ptr<NunchukManager> nunchukManager;
}

const int FEE_RATE_PRIORITY = CONF_TARGET_PRIORITY;
const int FEE_RATE_STANDARD = CONF_TARGET_STANDARD;
const int FEE_RATE_ECONOMICAL = CONF_TARGET_ECONOMICAL;
dispatch_queue_t nfcQueue = dispatch_queue_create("io.nunchuk.nfc", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, -1));
dispatch_semaphore_t semaphore;

- (id)init {
    self = [super init];
    nunchukManager = std::make_unique<NunchukManager>();
    return self;
}

- (void)enableLog:(BOOL)isEnabled {
    if (isEnabled) {
        loguru::g_stderr_verbosity = loguru::Verbosity_INFO;
    } else {
        loguru::g_stderr_verbosity = loguru::Verbosity_OFF;
    }
}

-(BOOL)importWallet:(NSBundle *)bundle error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        NSString *filePath = [bundle pathForResource:@"config" ofType:@"txt"];
        std::string path = [filePath UTF8String];
        nunchukManager->importConfig(path);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(NSString *)generateMnemonic:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return [NSString stringWithUTF8String: nunchukManager->generateMnemonic().c_str()];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)setupNunchukWithAccount:(NSString *)account passPhrase:(NSString *)passphrase settings:(ObjAppSettings *)settings deviceId:(NSString *)deviceId setupListener:(BOOL)setupListener error:(NSError * _Nullable __autoreleasing *)outError  {
    try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        nunchukManager->path = [documentsDirectory UTF8String];
        AppSettings appSettings;
        [self updateSettingsFrom:settings currentSettings:&appSettings storagePath:documentsDirectory];
        nunchukManager->setupNunChukForAccount([account UTF8String], [passphrase UTF8String], [deviceId UTF8String], [self](const std::string& roomId, const std::string& eventType, const std::string& eventContent, bool ignoreError) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(sendEventWithRoomId:evenType:content:ignoreError:)]) {
                NSString * str = [self.delegate sendEventWithRoomId:[NSString stringWithUTF8String:roomId.c_str()] evenType:[NSString stringWithUTF8String:eventType.c_str()] content:[NSString stringWithUTF8String:eventContent.c_str()] ignoreError: ignoreError];
                return [str UTF8String];
            } else {
                return [@"" UTF8String];
            }
        }, appSettings);
        
        if (setupListener) {
            [self observeWalletBalance];
            [self observeTransaction];
            [self observeBlock];
            [self observeConnectionStatus];
        }
        
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)setupNunchukWithDecoyPIN:(NSString *)pin settings:(ObjAppSettings *)settings setupListener:(BOOL)setupListener error:(NSError * _Nullable __autoreleasing *)error {
    try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        nunchukManager->path = [documentsDirectory UTF8String];
        AppSettings appSettings;
        [self updateSettingsFrom:settings currentSettings:&appSettings storagePath:documentsDirectory];
        nunchukManager->nu = MakeNunchukForDecoyPin(appSettings, [pin UTF8String]);
        if (setupListener) {
            [self observeWalletBalance];
            [self observeTransaction];
            [self observeBlock];
            [self observeConnectionStatus];
        }
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (void)observeConnectionStatus {
    nunchukManager->nu->AddBlockchainConnectionListener([self](ConnectionStatus status, int syncProgress) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateConnectionStatus:syncProgress:)]) {
            ConnectionStatusEnum connectionStatus = OFFLINE;
            if (status == ConnectionStatus::OFFLINE) {
                connectionStatus = OFFLINE;
            } else if (status == ConnectionStatus::ONLINE) {
                connectionStatus = ONLINE;
            } else if (status == ConnectionStatus::SYNCING) {
                connectionStatus = SYNCING;
            }
            [self.delegate didUpdateConnectionStatus:connectionStatus syncProgress:syncProgress];
        }
    });
}

- (void)observeWalletBalance {
    nunchukManager->nu->AddBalancesListener([self](std::string wid, Amount value, Amount amount) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateWalletBalance:walletId:)]) {
            [self.delegate didUpdateWalletBalance:amount walletId:[NSString stringWithUTF8String:wid.c_str()]];
        }
    });
}

- (void)observeBlock {
    nunchukManager->nu->AddBlockListener([self](int height, std::string hexHeader) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateBlock:hexHeader:)]) {
            [self.delegate didUpdateBlock:height hexHeader:[NSString stringWithUTF8String:hexHeader.c_str()]];
        }
    });
}

- (void)observeTransaction {
    nunchukManager->nu->AddTransactionListener([self](std::string wid, TransactionStatus status, std::string walletId) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateTransaction:walletId:status:)]) {
            NSString *str = [ObjTransaction transactionStatusFrom:status];
            [self.delegate didUpdateTransaction:[NSString stringWithUTF8String:wid.c_str()] walletId:[NSString stringWithUTF8String:walletId.c_str()] status:str];
        }
    });
}

- (NSString *)createWalletWithName:(NSString *)name numberKey:(int)numberKey signers:(NSMutableArray *)signers addressType:(NSString *)addressType type:(NSString *)type error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SingleSigner> remoteSigners;
        for(unsigned long i = 0; i < signers.count; i++) {
            if ([[signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                remoteSigners.push_back(signer);
            }
        }
        AddressType address_type = [self addressTypeFromString:addressType];
        WalletType wallet_type = [self walletTypeFromString:type];
        auto wallet = nunchukManager->nu->CreateWallet([name UTF8String], numberKey, [signers count], remoteSigners, address_type, wallet_type == WalletType::ESCROW);
        return [NSString stringWithUTF8String:wallet.get_id().c_str()];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)createTaprootWalletWithName:(NSString *)name numberKey:(int)numberKey signers:(NSMutableArray *)signers type:(NSString *)type valueKeyEnabled:(BOOL)valueKeyEnabled error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner> remoteSigners;
        for(unsigned long i = 0; i < signers.count; i++) {
            if ([[signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                remoteSigners.push_back(signer);
            }
        }
        WalletType wallet_type = [self walletTypeFromString:type];
        WalletTemplate walletTemplate = valueKeyEnabled ? WalletTemplate::DEFAULT : WalletTemplate::DISABLE_KEY_PATH;
        auto wallet = nunchukManager->nu->CreateWallet([name UTF8String], numberKey, [signers count], remoteSigners, AddressType::TAPROOT, wallet_type == WalletType::ESCROW, [@"" UTF8String], false, [@"" UTF8String], walletTemplate);
        return [NSString stringWithUTF8String:wallet.get_id().c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)createDecoyWallet:(NSString *)name numberKey:(int)numberKey signers:(NSMutableArray *)signers addressType:(NSString *)addressType type:(NSString *)type pin:(NSString *)pin error:(NSError * _Nullable __autoreleasing *)error {
    try {
        [self createDecoyPIN:pin];
        std::vector<SingleSigner> remoteSigners;
        for(unsigned long i = 0; i < signers.count; i++) {
            if ([[signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                remoteSigners.push_back(signer);
            }
        }
        AddressType address_type = [self addressTypeFromString:addressType];
        WalletType wallet_type = [self walletTypeFromString:type];
        auto wallet = nunchukManager->nu->CreateWallet([name UTF8String], numberKey, [signers count], remoteSigners, address_type, wallet_type == WalletType::ESCROW, [@"" UTF8String], false, [pin UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)createDecoyWallet:(NSString *)pin fromWalletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        [self createDecoyPIN:pin];
        auto wallet = nunchukManager->nu->CloneWallet([walletId UTF8String], [pin UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (void)createDecoyPIN:(NSString *)pin {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *storagePath = [paths objectAtIndex:0];
    BOOL exists = Utils::IsExistingDecoyPin([storagePath UTF8String], [pin UTF8String]);
    if (!exists) {
        Utils::NewDecoyPin([storagePath UTF8String], [pin UTF8String]);
    }
}

- (ObjWallet *)createHotWallet:(NSString *)passphrase error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        Wallet wallet = nunchukManager->nu->CreateHotWallet([@"" UTF8String], [passphrase UTF8String]);
        ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet: &wallet];
        return objWallet;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)recoverHotWallet:(NSString* _Nonnull)mnemonic passphrase:(NSString *)passphrase replace:(BOOL)replace error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        Wallet wallet = nunchukManager->nu->CreateHotWallet([mnemonic UTF8String], [passphrase UTF8String], false, replace);
        ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet: &wallet];
        return objWallet;
    } catch (const BaseException& exception) {
        if (exception.code() == StorageException::SIGNER_EXISTS) {
            *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorSignerExist userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
            return NULL;
        }
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSString *)getHotWalletMnemonic:(NSString *)walletId passphrase:(NSString *)passphrase error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return [NSString stringWithUTF8String: nunchukManager->nu->GetHotWalletMnemonic([walletId UTF8String], [passphrase UTF8String]).c_str()];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)confirmMnemonicHotWallet:(NSString *)walletId mnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase error:(NSError * _Nullable __autoreleasing *)outError {
    
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        if (wallet.need_backup()) {
            wallet.set_need_backup(false);
            nunchukManager->nu->UpdateWallet(wallet);
        }
        
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(NSString *)draftWalletWithName:(NSString *)name numberKey:(int)numberKey signers:(NSMutableArray *)signers addressType:(NSString *)addressType type:(NSString *)type desc:(NSString *)desc error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SingleSigner> remoteSigners;
        for(unsigned long i = 0; i < signers.count; i++) {
            if ([[signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                remoteSigners.push_back(signer);
            }
            if ([[signers objectAtIndex:i] isKindOfClass:[ObjMasterSigner class]]) {
                ObjMasterSigner *master = [signers objectAtIndex:i];
                auto allSigner = nunchukManager->nu->GetSignersFromMasterSigner([master.signerId UTF8String]);
                for (auto& signer: allSigner) {
                    remoteSigners.push_back(signer);
                }
            }
        }
        std::string descriptor = nunchukManager->draftMultisigWallet([name UTF8String], numberKey, remoteSigners, [desc UTF8String], [type UTF8String], [addressType UTF8String]);
        
        return [NSString stringWithUTF8String:descriptor.c_str()];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)exportWalletWithId:(NSString *)walletId filePath:(NSString *)filePath format:(NunchukExportFormat)format error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto exportFormat = [self parseExportFormat:format];
        return nunchukManager->nu->ExportWallet([walletId UTF8String], [filePath UTF8String], exportFormat);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjSingleSigner *)newRemoteSignerWithName:(NSString *)name xpub:(NSString *)xPub xpubKey:(NSString *)xPubkey path:(NSString *)path fingerprint:(NSString *)fingerPrint tags:(NSArray<NSString *>*)tags error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SignerTag> signertags;
        for (NSString *tag in tags) {
            signertags.push_back(SignerTagFromStr([tag UTF8String]));
        }
        auto signer = nunchukManager->nu->CreateSigner([name UTF8String], [xPub UTF8String], [xPubkey UTF8String], [path UTF8String], [fingerPrint UTF8String], SignerType::AIRGAP, signertags, true);
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)singleSignerWithName:(NSString *)name xpub:(NSString *)xPub xpubKey:(NSString *)xPubkey path:(NSString *)path fingerprint:(NSString *)fingerPrint externalInternalIndex:(IntPair *)externalInternalIndex error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::pair<int, int> index(0, 1);
        if (externalInternalIndex != nil) {
            index.first = externalInternalIndex.first;
            index.second = externalInternalIndex.second;
        }
        SingleSigner signer = SingleSigner([name UTF8String], [xPub UTF8String], [xPubkey UTF8String], [path UTF8String], index, [fingerPrint UTF8String], 0);
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)createNewMasterSignerWithName:(NSString *)name device:(ObjDevice *)device error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        Device cDevice = Device([device.type UTF8String], [device.path UTF8String], [device.model UTF8String], std::string([device.masterFingerPrint UTF8String]), device.needsPassPhraseSent, device.needsPinSent, device.initialized);
        nunchukManager->createNewMasterSigner([name UTF8String], cDevice);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(NSMutableArray<ObjSingleSigner *> *)getSigners:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto signers = nunchukManager->getSigners();
        NSMutableArray<ObjSingleSigner *> *array = [[NSMutableArray alloc] initWithCapacity:signers.size()];
        for(unsigned i = 0; i < signers.size(); i++) {
            auto signer = signers.at(i);
            ObjSingleSigner * objSigner = [[ObjSingleSigner alloc] initWithSigner: &signer];
            [array addObject: objSigner];
        }
        return array;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSMutableArray<ObjWallet *> *)getWallets:(BOOL)ordered error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        NSMutableArray<ObjWallet*> * objWallets = [[NSMutableArray alloc] init];
        std::vector<OrderBy> orders;
        if (ordered) {
            orders.push_back(OrderBy::MOST_RECENTLY_USED);
        }
        auto wallets = nunchukManager->nu->GetWallets(orders);
        for(unsigned i = 0; i < wallets.size(); i++) {
            ObjWallet * objWallet = [[ObjWallet alloc] initWithWallet:&wallets[i]];
            [objWallets addObject:objWallet];
            
        }
        return objWallets;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjWallet *)getWalletWithId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet: &wallet];
        return objWallet;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)updateSignerName:(NSString *)name path:(NSString *)path fingerprint:(NSString *)fingerPrint error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto signers = nunchukManager->getSigners();
        for(unsigned i = 0; i < signers.size(); i++) {
            auto signer = signers.at(i);
            auto fingerC = [fingerPrint UTF8String];
            auto pathC = [path UTF8String];
            
            if (signer.get_derivation_path().compare(pathC) == 0 && signer.get_master_fingerprint().compare(fingerC) == 0) {
                signer.set_name([name UTF8String]);
                nunchukManager->nu->UpdateRemoteSigner(signer);
                printf("\n----- update the name for wallet");
            }
        }
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)updateSignerName:(NSString *)name signerId:(NSString *)signerId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto masterSigners = nunchukManager->nu->GetMasterSigners();
        for(unsigned i = 0; i < masterSigners.size(); i++) {
            auto signer = masterSigners.at(i);
            if (signer.get_id().compare([signerId UTF8String]) == 0) {
                signer.set_name([name UTF8String]);
                signer.set_visible(true);
                nunchukManager->nu->UpdateMasterSigner(signer);
                printf("\n----- update the name for wallet");
            }
        }
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)removeSignerWithPath:(NSString *)path fingerprint:(NSString *)fingerPrint error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto signers = nunchukManager->getSigners();
        for(unsigned i = 0; i < signers.size(); i++) {
            auto signer = signers.at(i);
            auto fingerC = [fingerPrint UTF8String];
            auto pathC = [path UTF8String];
            
            if (signer.get_derivation_path().compare(pathC) == 0 && signer.get_master_fingerprint().compare(fingerC) == 0) {
                nunchukManager->nu->DeleteRemoteSigner(fingerC, pathC);
            }
        }
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}
-(BOOL)removeSignerWithId:(NSString *)signerId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        nunchukManager->nu->DeleteMasterSigner([signerId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)updateWalletNameWithId:(NSString *)walletId name:(NSString *)name error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        nunchukManager->updateWalletName([walletId UTF8String], [name UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)updateWalletGapLimitWithId:(NSString *)walletId limit:(int)limit error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        wallet.set_gap_limit(limit);
        nunchukManager->nu->UpdateWallet(wallet);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)setWalletArchive:(NSString *)walletId isArchive:(BOOL)isArchive error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        wallet.set_archived(isArchive);
        nunchukManager->nu->UpdateWallet(wallet);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjMasterSigner *)createSoftwareSignerWithName:(NSString *)raw_name mnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase replace:(BOOL)replace error:(NSError * _Nullable __autoreleasing *)outError {
    std::function<bool(int)> callback = [](int percent) {
        return true;
    };
    try {
        MasterSigner signer = nunchukManager->nu->CreateSoftwareSigner([raw_name UTF8String], [mnemonic UTF8String], [passphrase UTF8String], callback, false, replace);
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        if (exception.code() == StorageException::SIGNER_EXISTS) {
            *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorSignerExist userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
            return NULL;
        }
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjMasterSigner *)createHotKeyWithName:(NSString *)name error:(NSError **)error {
    std::function<bool(int)> callback = [](int percent) {
        return true;
    };
    try {
        auto mnemonic = Utils::GenerateMnemonic();
        auto signer = nunchukManager->nu->CreateSoftwareSigner([name UTF8String], mnemonic, [@"" UTF8String], callback);
        signer.set_need_backup(true);
        nunchukManager->nu->UpdateMasterSigner(signer);
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjMasterSigner *)create12WordsHotKeyWithName:(NSString *)name error:(NSError **)error {
    std::function<bool(int)> callback = [](int percent) {
        return true;
    };
    try {
        auto mnemonic = Utils::GenerateMnemonic12Words();
        auto signer = nunchukManager->nu->CreateSoftwareSigner([name UTF8String], mnemonic, [@"" UTF8String], callback);
        signer.set_need_backup(true);
        nunchukManager->nu->UpdateMasterSigner(signer);
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getHotKeyMnemonicWithSignerId:(NSString *)signerId error:(NSError **)error {
    try {
        return [NSString stringWithUTF8String: nunchukManager->nu->GetHotKeyMnemonic([signerId UTF8String]).c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)setSignerNeedBackup:(NSString *)signerId needBackup:(BOOL)needBackup error:(NSError **)error {
    try {
        auto signer = nunchukManager->nu->GetMasterSigner([signerId UTF8String]);
        signer.set_need_backup(needBackup);
        nunchukManager->nu->UpdateMasterSigner(signer);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjMasterSigner *)createSoftwareSignerFromMasterXprv:(NSString *)xprv name:(NSString *)name replace:(BOOL)replace error:(NSError * _Nullable __autoreleasing *)error {
    std::function<bool(int)> callback = [](int percent) {
        return true;
    };
    try {
        MasterSigner signer = nunchukManager->nu->CreateSoftwareSignerFromMasterXprv([name UTF8String], [xprv UTF8String], callback, false, replace);
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        if (exception.code() == StorageException::SIGNER_EXISTS) {
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorSignerExist userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
            return NULL;
        }
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjMasterSigner *)createPrimaryKeyWithName:(NSString *)name mnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase decoyPIN:(NSString *)decoyPIN error:(NSError * _Nullable __autoreleasing *)outError {
    std::function<bool(int)> callback = [](int percent) {
        return true;
    };
    try {
        MasterSigner signer = nunchukManager->nu->CreateSoftwareSigner([name UTF8String], [mnemonic UTF8String], [passphrase UTF8String], callback, YES, NO, [decoyPIN UTF8String]);
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjMasterSigner *)getSignerWithId:(NSString *)signerId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        MasterSigner signer = nunchukManager->nu->GetMasterSigner([signerId UTF8String]);
        
        return [[ObjMasterSigner alloc] initWithMasterSigner: &signer];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}
-(NSMutableArray<ObjMasterSigner *> *)getMasterSigners:(NSError * _Nullable __autoreleasing *)outError {
    try {
        NSMutableArray<ObjMasterSigner*> * array = [[NSMutableArray alloc] init];
        std::vector<MasterSigner> signers = nunchukManager->nu->GetMasterSigners();
        for(auto& signer: signers) {
            ObjMasterSigner * master = [[ObjMasterSigner alloc] initWithMasterSigner:&signer];
            [array addObject:master];
        }
        return array;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSMutableArray<NSString *> *)getBip39:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<std::string> list = Utils::GetBIP39WordList();
        NSMutableArray * mArray = [[NSMutableArray alloc] init];
        for(auto& str : list) {
            [mArray addObject:[[NSString alloc] initWithUTF8String: str.c_str()]];
        }
        return mArray;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSArray<ObjTransaction *> *)getTransactionsWithWalletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::string strId = [walletId UTF8String];
        NSMutableArray<ObjTransaction *> * array = [[NSMutableArray alloc] init];
        for(auto& trans : nunchukManager->nu->GetTransactionHistory(strId, 1000, 0)) {
            ObjTransaction * tran = [[ObjTransaction alloc] initWithTransaction: &trans];
            [array addObject:tran];
        }
        return [array copy];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjTransaction *)getTransactionWithWalletId:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto transaction = nunchukManager->nu->GetTransaction([walletId UTF8String], [txId UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction: &transaction];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSArray<NSString *> *)getAddressWithWalletId:(NSString *)walletId used:(BOOL)used internal:(BOOL)internal error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<std::string> addresses = nunchukManager->nu->GetAddresses([walletId UTF8String], used, internal);
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        for(auto& address: addresses) {
            [arr addObject:[NSString stringWithUTF8String:address.c_str()]];
        }
        return [arr copy];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSInteger)getAddressBalanceWithWalletId:(NSString *)walletId address:(NSString *)address error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->GetAddressBalance([walletId UTF8String], [address UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

- (BOOL)markAddressAsUsedWithWalletId:(NSString *)walletId address:(NSString *)address error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->MarkAddressAsUsed([walletId UTF8String], [address UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSString *)getAddressPathWithWalletId:(NSString *)walletId address:(NSString *)address error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        
        std::string addresses = nunchukManager->nu->GetAddressPath([walletId UTF8String], [address UTF8String]);
        return [NSString stringWithUTF8String:addresses.c_str()];
        
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

-(BOOL)isMnemonicValid:(NSString *)mnemonic error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return Utils::CheckMnemonic([mnemonic UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (SigningPath)getSigningPathFrom:(ObjSigningPath *)signingPath {
    SigningPath signing_path;
    for (NSArray *array in signingPath.scriptNodeIds) {
        ScriptNodeId nodeId;
        for (NSString *idStr in array) {
            const char *cString = [idStr UTF8String];
            size_t convertedSize = strtoull(cString, NULL, 10);
            nodeId.push_back(convertedSize);
        }
        signing_path.push_back(nodeId);
    }
    return signing_path;
}

- (ObjTransaction *)createTransactionWithWalletId:(NSString *)walletId outputs:(NSArray<StringIntPair *> *)outputs memo:(NSString *)memo feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount inputs:(NSArray *)inputs antiFeeSniping:(BOOL)antiFeeSniping useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *)signingPath error:(NSError * _Nullable __autoreleasing *)outError {
    std::map<std::string, Amount> cOutputs;
    
    for(NSUInteger i = 0; i < outputs.count; i++) {
        StringIntPair * pair = outputs[i];
        cOutputs[[pair.key UTF8String]] = pair.value;
    }
    
    std::vector<UnspentOutput> coinInputs;
    for (ObjUnspentOutput *input in inputs) {
        UnspentOutput cInput = [input convertToC];
        coinInputs.push_back(cInput);
    }
    
    try {
        Transaction createTx;
        if (signingPath == nil) {
            createTx = nunchukManager->nu->CreateTransaction(std::string([walletId UTF8String]), cOutputs, [memo UTF8String], coinInputs, feeRate, subtractFeeFromAmount, {}, antiFeeSniping, useScriptPath);
        } else {
            createTx = nunchukManager->nu->CreateTransaction(std::string([walletId UTF8String]), cOutputs, [memo UTF8String], coinInputs, feeRate, subtractFeeFromAmount, {}, antiFeeSniping, useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        auto tx = nunchukManager->nu->GetTransaction([walletId UTF8String], createTx.get_txid());
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjTransaction *)broadcastTransactionWithWalletId:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto tx = nunchukManager->nu->BroadcastTransaction([walletId UTF8String], [txId UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjDraftTransaction *)draftTransactionWithWalletId:(NSString *)walletId outputs:(NSArray<StringIntPair *> *)outputs inputs:(NSArray<ObjUnspentOutput *> *)input feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *)signingPath error:(NSError * _Nullable __autoreleasing *)outError {
    std::map<std::string, Amount> cOutputs;
    std::vector<UnspentOutput> inputs;
    for(NSUInteger i = 0; i < outputs.count; i++) {
        StringIntPair * pair = outputs[i];
        cOutputs[[pair.key UTF8String]] = pair.value;
    }
    
    for(NSUInteger i = 0; i < input.count; i++) {
        UnspentOutput cInput = [input[i] convertToC];
        inputs.push_back(cInput);
    }
    try {
        Transaction tx;
        if (signingPath == nil) {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), cOutputs, inputs, feeRate, subtractFeeFromAmount, {}, useScriptPath);
        } else {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), cOutputs, inputs, feeRate, subtractFeeFromAmount, {}, useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        ObjTransaction *draftTx = [[ObjTransaction alloc] initWithTransaction:&tx];
        Amount packageFeeRate{0};
        auto isCPFP = nunchukManager->nu->IsCPFP([walletId UTF8String], tx, packageFeeRate);
        
        NSMutableArray *keysetArray = [NSMutableArray new];
        if (useScriptPath) {
            auto keySet = tx.get_keyset_status();
            for (auto set : keySet) {
                ObjKeySetStatus *obj = [[ObjKeySetStatus alloc] initKeySetStatus:&set];
                [keysetArray addObject:obj];
            }
        }
        auto inputCoins = nunchukManager->nu->GetCoinsFromTxInputs([walletId UTF8String], tx.get_inputs());
        NSMutableArray *coinArray = [NSMutableArray array];
        for (auto &input : inputCoins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&input];
            [coinArray addObject:obj];
        }
        return [[ObjDraftTransaction alloc] initWithTransaction:draftTx IsCPFP:isCPFP packageFeeRate:packageFeeRate keySets:keysetArray inputCoins:coinArray];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjDraftTransaction *)draftRBFTransactionWithWalletId:(NSString *)walletId transactionId:(NSString *)transactionId outputs:(NSArray<StringIntPair *> *)outputs feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *_Nullable)signingPath error:(NSError * _Nullable __autoreleasing *)outError {
    std::map<std::string, Amount> cOutputs;
    for (NSUInteger i = 0; i < outputs.count; i++) {
        StringIntPair * pair = outputs[i];
        cOutputs[[pair.key UTF8String]] = pair.value;
    }
    
    try {
        auto oldTx = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        if (oldTx.get_status() == TransactionStatus::CONFIRMED) {
            throw BaseException(NunchukSDKErrorInvalidTxStatus, "Cannot replace transaction. The original transaction has already been confirmed");
        }
        auto input = nunchukManager->nu->GetUnspentOutputsFromTxInputs([walletId UTF8String], oldTx.get_inputs());
        Transaction tx;
        if (signingPath == nil) {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), cOutputs, input, feeRate, subtractFeeFromAmount, [transactionId UTF8String], useScriptPath);
        } else {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), cOutputs, input, feeRate, subtractFeeFromAmount, [transactionId UTF8String], useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        ObjTransaction *draftTx = [[ObjTransaction alloc] initWithTransaction:&tx];
        Amount packageFeeRate{0};
        auto isCPFP = nunchukManager->nu->IsCPFP([walletId UTF8String], tx, packageFeeRate);
        auto inputCoins = nunchukManager->nu->GetCoinsFromTxInputs([walletId UTF8String], tx.get_inputs());
        NSMutableArray *coinArray = [NSMutableArray array];
        for (auto &input : inputCoins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&input];
            [coinArray addObject:obj];
        }
        return [[ObjDraftTransaction alloc] initWithTransaction:draftTx IsCPFP:isCPFP packageFeeRate:packageFeeRate keySets:@[] inputCoins:coinArray];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjDraftTransaction *)draftCancelRBFTransactionWithWalletId:(NSString *)walletId transactionId:(NSString *)transactionId newAddress:(NSString *)newAddress newFeeRate:(long)newFeeRate useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *)signingPath error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto originTx = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        if (originTx.get_status() == TransactionStatus::CONFIRMED) {
            throw BaseException(NunchukSDKErrorInvalidTxStatus, "Cannot replace transaction. The original transaction has already been confirmed");
        }
        auto inputs = nunchukManager->nu->GetUnspentOutputsFromTxInputs([walletId UTF8String], originTx.get_inputs());
        auto totalAmount = 0;
        for (auto input : inputs) {
            totalAmount += input.get_amount();
        }
        std::map<std::string, Amount> outputs;
        outputs[[newAddress UTF8String]] = totalAmount;
        Transaction tx;
        if (signingPath == nil) {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), outputs, inputs, newFeeRate, YES, [transactionId UTF8String], useScriptPath);
        } else {
            tx = nunchukManager->nu->DraftTransaction(std::string([walletId UTF8String]), outputs, inputs, newFeeRate, YES, [transactionId UTF8String], useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        ObjTransaction *draftTx = [[ObjTransaction alloc] initWithTransaction:&tx];
        Amount packageFeeRate{0};
        auto isCPFP = nunchukManager->nu->IsCPFP([walletId UTF8String], tx, packageFeeRate);
        auto inputCoins = nunchukManager->nu->GetCoinsFromTxInputs([walletId UTF8String], tx.get_inputs());
        NSMutableArray *coinArray = [NSMutableArray array];
        for (auto &input : inputCoins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&input];
            [coinArray addObject:obj];
        }
        return [[ObjDraftTransaction alloc] initWithTransaction:draftTx IsCPFP:isCPFP packageFeeRate:packageFeeRate keySets:@[] inputCoins:coinArray];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)consumeEvent:(ObjNunchukMatrixEvent *)event error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->ConsumeEvent(nunchukManager->nu, [event getNunchukEvent]);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)updateTransactionMemoWithWalletId:(NSString *)walletId txId:(NSString *)txId newMemo:(NSString *)newMemo error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->UpdateTransactionMemo([walletId UTF8String], [txId UTF8String], [newMemo UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(NSInteger)estimatFee:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->EstimateFee();
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

-(NSInteger)estimatFeeWithConfig:(int)conf error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->EstimateFee(conf);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

-(NSString *)newAddressWithWalletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return [[NSString alloc] initWithUTF8String: nunchukManager->nu->NewAddress([walletId UTF8String]).c_str()];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)deleteTransactionWithWalletId:(NSString *)walletId txId:(NSString *)transactionId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->DeleteTransaction([walletId UTF8String], [transactionId UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjTransaction *)signTransactionWithWalletId:(NSString *)walletId txId:(NSString *)txId fingerprint:(NSString *)fingerPrint error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        Device cDevice = nunchukManager->nu->GetMasterSigner([fingerPrint UTF8String]).get_device();
        auto tx = nunchukManager->nu->SignTransaction(std::string([walletId UTF8String]), std::string([txId UTF8String]), cDevice);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSInteger)getTotalAmountWithWalletId:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto tx = nunchukManager->nu->GetTransaction(std::string([walletId UTF8String]), std::string([txId UTF8String]));
        
        return nunchukManager->nu->GetTotalAmount(std::string([walletId UTF8String]), tx.get_inputs());
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

-(BOOL)deleteWalletWithWalletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->DeleteWallet([walletId UTF8String]);
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)sendPassphrase:(NSString *)passphrase signerId:(NSString *)signerId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        nunchukManager->nu->SendSignerPassphrase([signerId UTF8String], [passphrase UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjWallet *)importBSMSWithFilePath:(NSString *)filePath walletName:(NSString *)walletName error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto wallet =  nunchukManager->nu->ImportWalletDescriptor([filePath UTF8String], [walletName UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSInteger)getChainTip:(NSError * _Nullable __autoreleasing *)outError {
    try {
        return nunchukManager->nu->GetChainTip();
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return 0;
    }
}

// MARK: - Shared wallet
-(ObjNunchukMatrixEvent *)initializeWalletWithRoomId:(NSString *)roomId name:(NSString *)name min:(int)m total:(int)n addressType:(NSString *)addressType isEscrow:(BOOL)isEsrow desc:(NSString *)desc error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            AddressType address_type = [self addressTypeFromString:addressType];
            auto event = nunchukManager->nuMatrix->InitWallet([roomId UTF8String], [name UTF8String], m, n, address_type, isEsrow);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)joinWalletWithRoomId:(NSString *)roomId signers:(NSArray *)signers walletType:(NSString *)walletTypeStr addressType:(NSString *)addressTypeStr error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            for (id signer in signers) {
                if ([signer isKindOfClass:[ObjSingleSigner class]]) {
                    ObjSingleSigner *remoteSigner = (ObjSingleSigner *)signer;
                    std::pair<int, int> externalInternalIndex(0, 1);
                    if (remoteSigner.externalInternalIndex != nil) {
                        externalInternalIndex.first = remoteSigner.externalInternalIndex.first;
                        externalInternalIndex.second = remoteSigner.externalInternalIndex.second;
                    }
                    auto cSigner = SingleSigner(std::string([remoteSigner.signerName UTF8String]), std::string([remoteSigner.xpub UTF8String]), std::string([remoteSigner.publicKey UTF8String]), std::string([remoteSigner.bip32Path UTF8String]), externalInternalIndex, std::string([remoteSigner.masterFingerPrint UTF8String]), false);
                    cSigner.set_type([self parseObjCSignerType:remoteSigner.type]);
                    auto event = nunchukManager->nuMatrix->JoinWallet([roomId UTF8String], cSigner);
                }
            }
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjNunchukMatrixEvent *)leaveWalletWithRoomId:(NSString *)roomId joinId:(NSString *)joinId reason:(NSString *)reason error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->LeaveWallet([roomId UTF8String], [joinId UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent: event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:0 userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)cancelWalletWithRoomId:(NSString *)roomId reason:(NSString *)reason error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->CancelWallet([roomId UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent: event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)createWalletWithRoomId:(NSString *)roomId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->CreateWallet(nunchukManager->nu, [roomId UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent: event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (AddressType)addressTypeFromString: (NSString *)addressType {
    if (std::strcmp([addressType UTF8String], "NATIVE_SEGWIT") == 0) {
        return AddressType::NATIVE_SEGWIT;
    }
    
    if (std::strcmp([addressType UTF8String], "LEGACY") == 0) {
        return AddressType::LEGACY;
    }
    
    if (std::strcmp([addressType UTF8String], "NESTED_SEGWIT") == 0) {
        return AddressType::NESTED_SEGWIT;
    }
    
    if (std::strcmp([addressType UTF8String], "TAPROOT") == 0) {
        return AddressType::TAPROOT;
    }
    
    return AddressType::ANY;
}

- (WalletType)walletTypeFromString: (NSString *)walletType {
    if (std::strcmp([walletType UTF8String], "SINGLE_SIG") == 0) {
        return WalletType::SINGLE_SIG;
    }
    
    if (std::strcmp([walletType UTF8String], "ESCROW") == 0) {
        return WalletType::ESCROW;
    }
    
    if (std::strcmp([walletType UTF8String], "MULTI_SIG") == 0) {
        return WalletType::MULTI_SIG;
    }
    return WalletType::SINGLE_SIG;
}

-(ObjRoomWallet *)getRoomWalletWithRoomId:(NSString *)roomId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto roomWallet = nunchukManager->getRoomWallet([roomId UTF8String]);
        return [[ObjRoomWallet alloc] initWithRoomWallet: &roomWallet];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)getEventWithEventId:(NSString *)eventId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto matrixEvent = nunchukManager->nuMatrix->GetEvent([eventId UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent: matrixEvent];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)consumeSyncEvent:(ObjNunchukMatrixEvent *)event withProgress:(BOOL (^)(int))consumeProgress error:(NSError * _Nullable __autoreleasing *)outError {
    auto matrixEvent = [event getNunchukEvent];
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->ConsumeSyncEvent(nunchukManager->nu, matrixEvent, [consumeProgress](int progress) {
                return consumeProgress(progress);
            });
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        consumeProgress(-1);
        return NO;
    }
}

-(BOOL)consumeSyncFileWith:(NSString *)fileJsonInfo filePath:(NSString *)filePath withProgressBlock:(BOOL (^)(int))progressBlock error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->WriteFileCallback(nunchukManager->nu, [fileJsonInfo UTF8String], [filePath UTF8String], [progressBlock](int progress) {
                return progressBlock(progress);
            });
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        progressBlock(-1);
        return NO;
    }
}

- (BOOL)registerAutoBackupWithRoomId:(NSString *)roomId accessToken:(NSString *)accessToken error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            self.syncRoomId = roomId;
            nunchukManager->nuMatrix->RegisterAutoBackup(nunchukManager->nu,
                                                         [roomId UTF8String],
                                                         [accessToken UTF8String]);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)enableAutoBackup:(BOOL)enabled error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->EnableAutoBackup(enabled);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)backupWithError:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->Backup(nunchukManager->nu);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)registerDownloadAndUploadFile:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->RegisterFileFunc([self](const std::string& fileName, const std::string& mineType, const std::string& fileJsonInfo, const char* data, size_t dataLength) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveUploadRequestWithRoomId:fileName:mineType:fileJsonInfo:data:)]) {
                    [self.delegate didReceiveUploadRequestWithRoomId:self.syncRoomId fileName:[NSString stringWithUTF8String:fileName.c_str()] mineType:[NSString stringWithUTF8String:fileName.c_str()] fileJsonInfo:[NSString stringWithUTF8String:fileJsonInfo.c_str()] data:[NSData dataWithBytes:data length:dataLength]];
                }
                return [@"" UTF8String];
            }, [self](const std::string& fileName, const std::string& mineType, const std::string& fileJsonInfo, const std::string& mxcUri) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveDownloadRequestWithFileName:mineType:fileJsonInfo:mxcUri:)]) {
                    [self.delegate didReceiveDownloadRequestWithFileName:[NSString stringWithUTF8String:fileName.c_str()]
                                                                mineType:[NSString stringWithUTF8String:fileName.c_str()]
                                                            fileJsonInfo:[NSString stringWithUTF8String:fileJsonInfo.c_str()]
                                                                  mxcUri:[NSString stringWithUTF8String:mxcUri.c_str()]];
                }
                std::vector<unsigned char> data;
                return data;
            });
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(BOOL)backupFileWithFileJsonInfo:(NSString *)fileJsonInfo fileURL:(NSString *)fileURL error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->UploadFileCallback([fileJsonInfo UTF8String], [fileURL UTF8String]);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(ObjNunchukMatrixEvent *)initialzeTransactionWithRoomId:(NSString *)roomId outputs:(NSArray<StringIntPair *> *)outputs memo:(NSString *)memo inputs:(NSArray<ObjUnspentOutput *> *)inputs feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError * _Nullable __autoreleasing *)outError {
    std::map<std::string, Amount> cOutputs;
    
    for(StringIntPair *pair in outputs) {
        cOutputs[[pair.key UTF8String]] = pair.value;
    }
    std::vector<UnspentOutput> cInputs;
    for (ObjUnspentOutput *input in inputs) {
        auto cInput = [input convertToC];
        cInputs.push_back(cInput);
    }
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->InitTransaction(nunchukManager->nu, [roomId UTF8String], cOutputs, [memo UTF8String], cInputs, feeRate, subtractFeeFromAmount);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)signTransactionWithInitEventId:(NSString *)initEventId device:(ObjDevice *)device error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto cDevice = Device([device.type UTF8String], [device.path UTF8String], [device.model UTF8String], [device.masterFingerPrint UTF8String], device.needsPassPhraseSent, device.needsPinSent, device.initialized);
            auto event = nunchukManager->nuMatrix->SignTransaction(nunchukManager->nu, [initEventId UTF8String], cDevice);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)rejectTransactionWithInitEventId:(NSString *)initEventId reason:(NSString *)reason error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->RejectTransaction([initEventId UTF8String], [reason UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)cancelTransactionWithInitEventId:(NSString *)initEventId reason:(NSString *)reason error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->CancelTransaction([initEventId UTF8String], [reason UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjNunchukMatrixEvent *)broadcastTransactionWithInitEventId:(NSString *)initEventId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->BroadcastTransaction(nunchukManager->nu, [initEventId UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)enableGenerateReceiveEvent:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->EnableGenerateReceiveEvent(nunchukManager->nu);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

-(NSArray<ObjRoomTransaction *> *)getPendingTransactionsWithRoomId:(NSString *)roomId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            NSMutableArray<ObjRoomTransaction *> *pendingTxs = [[NSMutableArray alloc] init];
            auto cPendingTxs = nunchukManager->nuMatrix->GetPendingTransactions([roomId UTF8String]);
            for (auto& cPendingTx : cPendingTxs) {
                ObjRoomTransaction *pendingTx = [[ObjRoomTransaction alloc] initWithRoomTransaction: &cPendingTx];
                [pendingTxs addObject: pendingTx];
            }
            return pendingTxs;
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjRoomTransaction *)getRoomTransactionWithInitEventId:(NSString *)initEventId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto roomTx = nunchukManager->nuMatrix->GetRoomTransaction([initEventId UTF8String]);
            return [[ObjRoomTransaction alloc] initWithRoomTransaction:&roomTx];
        }
        return NULL;
    }
    catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSString *)getTransactionIdWithEventId:(NSString *)eventId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            auto txId = nunchukManager->nuMatrix->GetTransactionId([eventId UTF8String]);
            return [NSString stringWithUTF8String:txId.c_str()];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjAppSettings *)getNetworkSettings:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto appSettings = nunchukManager->nu->GetAppSettings();
        return [[ObjAppSettings alloc] initWithAppSetting:&appSettings];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(BOOL)updateSettings:(ObjAppSettings *)settings error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        AppSettings appSettings = nunchukManager->nu->GetAppSettings();
        [self updateSettingsFrom:settings currentSettings:&appSettings storagePath:nil];
        nunchukManager->nu->UpdateAppSettings(appSettings);
        return YES;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (void)updateSettingsFrom:(ObjAppSettings *)settings currentSettings:(AppSettings *)appSettings storagePath:(NSString *)storagePath {
    if (settings == nil) {
        appSettings->set_chain(Chain::TESTNET);
        appSettings->enable_proxy(false);
        appSettings->set_testnet_servers({"testnet.nunchuk.io:50001"});
        appSettings->set_mainnet_servers({"mainnet.nunchuk.io:51001"});
        appSettings->set_signet_servers({"signet.nunchuk.io:50002"});
        appSettings->set_backend_type(BackendType::ELECTRUM);
        appSettings->set_hwi_path("bin/hwi");
        appSettings->set_storage_path([storagePath UTF8String]);
        return;
    }
    
    appSettings->set_hwi_path([settings.hwiPath UTF8String]);
    appSettings->set_storage_path(nunchukManager->path);
    
    switch (settings.chain) {
        case MAIN:
            appSettings->set_chain(Chain::MAIN);
            break;
        case TESTNET:
            appSettings->set_chain(Chain::TESTNET);
            break;
        case REGTEST:
            appSettings->set_chain(Chain::REGTEST);
            break;
        case SIGNET:
            appSettings->set_chain(Chain::SIGNET);
            break;
    }
    
    switch (settings.backend) {
        case ELECTRUM:
            appSettings->set_backend_type(BackendType::ELECTRUM);
            break;
        case CORERPC:
            appSettings->set_backend_type(BackendType::CORERPC);
            break;
            break;
    }
    
    std::vector<std::string> mainnetServers;
    for (NSString *server in settings.mainnetServers) {
        mainnetServers.push_back([server UTF8String]);
    }
    appSettings->set_mainnet_servers(mainnetServers);
    
    std::vector<std::string> testnetServers;
    for (NSString *server in settings.testnetServers) {
        testnetServers.push_back([server UTF8String]);
    }
    appSettings->set_testnet_servers(testnetServers);
    
    std::vector<std::string> signetServers;
    for (NSString *server in settings.signetServers) {
        signetServers.push_back([server UTF8String]);
    }
    appSettings->set_signet_servers(signetServers);
    
    appSettings->enable_proxy(settings.isProxyEnabled);
    appSettings->set_proxy_host([settings.proxyHost UTF8String]);
    appSettings->set_proxy_port(settings.proxyPort);
    appSettings->set_proxy_username([settings.proxyUsername UTF8String]);
    appSettings->set_proxy_password([settings.proxyPassword UTF8String]);
    
    appSettings->set_certificate_file([settings.certificateFile UTF8String]);
    
    appSettings->set_corerpc_host([settings.coreRPCHost UTF8String]);
    appSettings->set_corerpc_port(settings.coreRPCPort);
    appSettings->set_corerpc_username([settings.coreRPCUsername UTF8String]);
    appSettings->set_corerpc_password([settings.corePRCPassword UTF8String]);
    if (settings.groupServerURL != nil && settings.groupServerURL.length > 0) {
        appSettings->set_group_server([settings.groupServerURL UTF8String]);
    }
}

- (NSArray<ObjRoomWallet *> *)getAllRoomWallets:(NSError * _Nullable __autoreleasing *)outError {
    try {
        if (nunchukManager->nuMatrix) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            auto roomWallets = nunchukManager->nuMatrix->GetAllRoomWallets();
            for (auto &roomWallet: roomWallets) {
                [result addObject: [[ObjRoomWallet alloc] initWithRoomWallet: &roomWallet]];
            }
            return result;
        }
        return NULL;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

// Keystone
-(NSArray<NSString *> *)exportKeystoneWalletWithId:(NSString *)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto datas = nunchukManager->nu->ExportKeystoneWallet([walletId UTF8String], fragmentLength);
        NSMutableArray *keystones = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [keystones addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return keystones;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(NSArray *)exportBCUR2:(NSString *)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto datas = nunchukManager->nu->ExportBCR2020010Wallet([walletId UTF8String], fragmentLength);
        NSMutableArray *qrs = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [qrs addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return qrs;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<NSString *> *)exportBBQRWalletWithId:(NSString *)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        std::vector<std::string> datas;
        if (wallet.get_wallet_type() == WalletType::MINISCRIPT) {
            datas = Utils::ExportBBQRWallet(wallet, ExportFormat::DESCRIPTOR_EXTERNAL_INTERNAL, 1, fragmentLength);
        } else {
            datas = Utils::ExportBBQRWallet(wallet, ExportFormat::COLDCARD, 1, fragmentLength);
        }
        NSMutableArray *bbqrs = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [bbqrs addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return bbqrs;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<NSString *> *)exportBBQRTransactionWithWalletId:(NSString *)walletId txId:(NSString *)txId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        NSString *psbt = [self getTransactionPSBT:txId walletId:walletId error:outError];
        auto datas = Utils::ExportBBQRTransaction([psbt UTF8String], 1, fragmentLength);
        NSMutableArray *bbqrs = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [bbqrs addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return bbqrs;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjWallet *)importKeystoneWalletWithQrs:(NSArray<NSString *> *)qrDatas description:(NSString *)description error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<std::string> cQrDatas;
        for (NSString *qrData in qrDatas) {
            cQrDatas.push_back([qrData UTF8String]);
        }
        auto wallet = nunchukManager->nu->ImportKeystoneWallet(cQrDatas, [description UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return [self parseWalletDescriptorWithQrs: qrDatas description:description error:outError];
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return [self parseWalletDescriptorWithQrs: qrDatas description:description error:outError];
    }
}

-(ObjWallet *)parseWalletDescriptorWithQrs:(NSArray<NSString *> *)qrDatas description:(NSString *)description error:(NSError * _Nullable __autoreleasing *)outError {
    if (qrDatas.count == 1) {
        return [self parseWalletDescriptor:[qrDatas objectAtIndex:0] error:outError];
    } else {
        return NULL;
    }
}

-(NSArray<NSString *> *)exportKeystoneTransactionWithWalletId:(NSString *)walletId txId:(NSString *)txId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto datas = nunchukManager->nu->ExportKeystoneTransaction([walletId UTF8String], [txId UTF8String], fragmentLength);
        NSMutableArray *keystones = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [keystones addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return keystones;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjTransaction *)importKeystoneTransactionWithWalletId:(NSString *)walletId qrData:(NSArray<NSString *> *)qrDatas error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<std::string> cQrDatas;
        for (NSString *qrData in qrDatas) {
            cQrDatas.push_back([qrData UTF8String]);
        }
        auto transaction = nunchukManager->nu->ImportKeystoneTransaction([walletId UTF8String], cQrDatas);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)importPSBTWith:(NSString *)walletId base64Pspt:(NSString *)psbt error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto transaction = nunchukManager->nu->ImportPsbt([walletId UTF8String], [psbt UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)exportTransaction:(NSString *)walletId txId:(NSString *)txId filePath:(NSString *)filePath error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto result = nunchukManager->nu->ExportTransaction([walletId UTF8String], [txId UTF8String], [filePath UTF8String]);
        return result;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)importTransaction:(NSString *)walletId filePath:(NSString *)filePath error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto transaction = nunchukManager->nu->ImportTransaction([walletId UTF8String], [filePath UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)healthCheckSingleSigner:(ObjSingleSigner *)signer
                        message:(NSString *)message
                      signature:(NSString *)signature
                          error:(NSError **)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (signer.externalInternalIndex != nil) {
            externalInternalIndex.first = signer.externalInternalIndex.first;
            externalInternalIndex.second = signer.externalInternalIndex.second;
        }
        SingleSigner singleSigner = SingleSigner([signer.signerName UTF8String], [signer.xpub UTF8String], [signer.publicKey UTF8String], [signer.bip32Path UTF8String], externalInternalIndex, [signer.masterFingerPrint UTF8String], signer.lastHealthCheckTS);
        singleSigner.set_type([self parseObjCSignerType:signer.type]);
        nunchukManager->nu->HealthCheckSingleSigner(singleSigner, [message UTF8String], [signature UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)healthCheckMasterSigner:(ObjMasterSigner *)signer
                        message:(NSString *)message
                      signature:(NSString *)signature
                           path:(NSString *)path
                          error:(NSError **)error {
    try {
        std::string messageStr = std::string([message UTF8String]);
        std::string signatureStr = std::string([signature UTF8String]);
        std::string pathStr = std::string([path UTF8String]);
        nunchukManager->nu->HealthCheckMasterSigner([signer.device.masterFingerPrint UTF8String], messageStr, signatureStr, pathStr);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (KeyHealthStatus)parseHealthStatus:(HealthStatus)status {
    switch (status) {
        case nunchuk::HealthStatus::SUCCESS:
            return SUCCESS;
        case nunchuk::HealthStatus::FINGERPRINT_NOT_MATCHED:
            return FINGERPRINT_NOT_MATCHED;
        case nunchuk::HealthStatus::NO_SIGNATURE:
            return NO_SIGNATURE;
        case nunchuk::HealthStatus::SIGNATURE_INVALID:
            return SIGNATURE_INVALID;
        case nunchuk::HealthStatus::KEY_NOT_MATCHED:
            return KEY_NOT_MATCHED;
    }
}

- (BOOL)sendErrorEvent:(NSString *)roomId
              platform:(NSString *)platform
                  code:(NSString *)code
               message:(NSString *)message
                 error:(NSError **)error {
    try {
        if (nunchukManager->nuMatrix) {
            nunchukManager->nuMatrix->SendErrorEvent([roomId UTF8String], [platform UTF8String], [code UTF8String], [message UTF8String]);
            return YES;
        }
        return NO;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (SignerType)parseObjCSignerType:(ObjCSignerType)type {
    switch (type) {
        case HARDWARE:
            return SignerType::HARDWARE;
        case AIRGAP:
            return SignerType::AIRGAP;
        case SOFTWARE:
            return SignerType::SOFTWARE;
        case FOREIGN_SOFTWARE:
            return SignerType::FOREIGN_SOFTWARE;
        case NFC:
            return SignerType::NFC;
        case ColdCardNFC:
            return SignerType::COLDCARD_NFC;
        case PortalNFC:
            return SignerType::PORTAL_NFC;
        case UNKNOWN_SignerType:
            return SignerType::UNKNOWN;
        case SERVER:
            return SignerType::SERVER;
    }
}

- (BOOL)hasRoomWallet:(NSString *)roomId {
    try {
        if (nunchukManager->nuMatrix) {
            return nunchukManager->nuMatrix->HasRoomWallet([roomId UTF8String]);
        }
        return NO;
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSString *)signLoginMessageWithKeyId:(NSString *)keyId message:(NSString *)message {
    try {
        NSString *signature = [NSString stringWithUTF8String: nunchukManager->nu->SignLoginMessage([keyId UTF8String], [message UTF8String]).c_str()];
        return signature;
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (BOOL)deletePrimaryKeyWithError:(NSError **)error; {
    try {
        nunchukManager->nu->DeletePrimaryKey();
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjNunchukMatrixEvent *)recoverSharedWallet:(NSString *)roomId name:(NSString *)name wallet:(ObjWallet *)wallet error:(NSError **)error {
    try {
        if (nunchukManager->nuMatrix) {
            AddressType addressType = [self addressTypeFromString:wallet.addressType];
            std::vector<SingleSigner> signers;
            for(unsigned long i = 0; i < wallet.signers.count; i++) {
                if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                    ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                    std::pair<int, int> externalInternalIndex(0, 1);
                    if (rmSigner.externalInternalIndex != nil) {
                        externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                        externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                    }
                    auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                    signer.set_type([self parseObjCSignerType:rmSigner.type]);
                    signers.push_back(signer);
                }
            }
            
            auto event = nunchukManager->nuMatrix->InitWallet([roomId UTF8String], [name UTF8String], wallet.m, wallet.n, addressType, wallet.isEscrow, [wallet.desc UTF8String], signers);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)hasSigner:(ObjSingleSigner *)signer {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (signer.externalInternalIndex != nil) {
            externalInternalIndex.first = signer.externalInternalIndex.first;
            externalInternalIndex.second = signer.externalInternalIndex.second;
        }
        auto singleSigner = SingleSigner(std::string([signer.signerName UTF8String]), std::string([signer.xpub UTF8String]), std::string([signer.publicKey UTF8String]), std::string([signer.bip32Path UTF8String]), externalInternalIndex, std::string([signer.masterFingerPrint UTF8String]), false);
        singleSigner.set_type([self parseObjCSignerType:signer.type]);
        return nunchukManager->nu->HasSigner(singleSigner);
    } catch (const std::exception& exception) {
        return FALSE;
    }
}

- (ObjWallet *)parseWalletDescriptor:(NSString *)content error:(NSError **)error {
    try {
        auto wallet = Utils::ParseWalletDescriptor([content UTF8String]);
        ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet:&wallet];
        return objWallet;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)parseKeystoneWallet:(NSArray *)data chain:(ChainTypeEnum)chain error:(NSError **)error {
    try {
        std::vector<std::string> cQrDatas;
        for (NSString *qrData in data) {
            cQrDatas.push_back([qrData UTF8String]);
        }
        Chain chainValue = Chain::MAIN;
        switch (chain) {
            case MAIN:
                chainValue = Chain::MAIN;
                break;
            case TESTNET:
                chainValue = Chain::TESTNET;
                break;
            case REGTEST:
                chainValue = Chain::REGTEST;
                break;
            case SIGNET:
                chainValue = Chain::SIGNET;
                break;
        }
        auto wallet = Utils::ParseKeystoneWallet(chainValue, cQrDatas);
        ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet:&wallet];
        return objWallet;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)replaceTransaction:(NSString *)transactionId walletId:(NSString *)walletId newFeeRate:(long)newFeeRate antiFeeSniping:(BOOL)antiFeeSniping useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *)signingPath error:(NSError **)error {
    try {
        auto replaceTx = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        if (replaceTx.get_status() == TransactionStatus::CONFIRMED) {
            throw BaseException(NunchukSDKErrorInvalidTxStatus, "Cannot replace transaction. The original transaction has already been confirmed");
        }
        Transaction tx;
        if (signingPath == nil) {
            tx = nunchukManager->nu->ReplaceTransaction([walletId UTF8String], [transactionId UTF8String], newFeeRate, antiFeeSniping, useScriptPath);
        } else {
            tx = nunchukManager->nu->ReplaceTransaction([walletId UTF8String], [transactionId UTF8String], newFeeRate, antiFeeSniping, useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)cancelRBFTransaction:(NSString *)transactionId walletId:(NSString *)walletId newFeeRate:(long)newFeeRate newAddress:(NSString *)newAddress antiFeeSniping:(BOOL)antiFeeSniping useScriptPath:(BOOL)useScriptPath signingPath:(ObjSigningPath *)signingPath error:(NSError **)error {
    try {
        auto originTx = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        if (originTx.get_status() == TransactionStatus::CONFIRMED) {
            throw BaseException(NunchukSDKErrorInvalidTxStatus, "Cannot replace transaction. The original transaction has already been confirmed");
        }
        auto inputs = nunchukManager->nu->GetUnspentOutputsFromTxInputs([walletId UTF8String], originTx.get_inputs());
        auto totalAmount = 0;
        for (auto input : inputs) {
            totalAmount += input.get_amount();
        }
        std::map<std::string, Amount> outputs;
        outputs[[newAddress UTF8String]] = totalAmount;
        Transaction tx;
        if (signingPath == nil) {
            tx = nunchukManager->nu->CreateTransaction([walletId UTF8String], outputs, [@"" UTF8String], inputs, newFeeRate, true, [transactionId UTF8String], antiFeeSniping, useScriptPath);
        } else {
            tx = nunchukManager->nu->CreateTransaction([walletId UTF8String], outputs, [@"" UTF8String], inputs, newFeeRate, true, [transactionId UTF8String], antiFeeSniping, useScriptPath, [self getSigningPathFrom:signingPath]);
        }
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjNunchukMatrixEvent *)signAirgapTransactionWithInitEventId:(NSString *)initEventId masterFingerprint:(NSString *)masterFingerprint error:(NSError * _Nullable __autoreleasing *)error {
    try {
        if (nunchukManager->nuMatrix) {
            auto event = nunchukManager->nuMatrix->SignAirgapTransaction(nunchukManager->nu, [initEventId UTF8String], [masterFingerprint UTF8String]);
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)clearPassPhraseWithSignerId:(NSString *)signerId error:(NSError **)error {
    try {
        nunchukManager->nu->ClearSignerPassphrase([signerId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)setSelectedWallet:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->SetSelectedWallet([walletId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSArray<ObjSingleSigner *>*)parseQRSignersWithQRDatas:(NSArray<NSString *> *)qrDatas error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string> cQrDatas;
        for (NSString *qrData in qrDatas) {
            cQrDatas.push_back([qrData UTF8String]);
        }
        auto signers = nunchukManager->nu->ParseQRSigners(cQrDatas);
        NSMutableArray<ObjSingleSigner *>* remoteSigners = [[NSMutableArray alloc] init];
        for (auto signer: signers) {
            [remoteSigners addObject:[[ObjSingleSigner alloc] initWithSigner:&signer]];
        }
        return remoteSigners;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)parseAirgapJsonSignerWithJson:(NSString *)json error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto signers = nunchukManager->nu->ParseJSONSigners([json UTF8String], SignerType::AIRGAP);
        NSMutableArray *remoteSigners = [[NSMutableArray alloc] init];
        for (auto signer: signers) {
            ObjSingleSigner *remoteSigner = [[ObjSingleSigner alloc] initWithSigner:&signer];
            [remoteSigners addObject:remoteSigner];
        }
        return remoteSigners;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

// MARK: - Tapsigner

- (std::unique_ptr<Tapsigner>)createTapsignerWithError:(NSError **)error {
    self.session = [[NFCTagReaderSession alloc] initWithPollingOption:NFCPollingISO14443 | NFCPollingISO15693 | NFCPollingISO18092 delegate:self queue:nfcQueue];
    [self.session setAlertMessage:@"Put your device near the NFC key."];
    [self.session beginSession];
    semaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    id<NFCTag> tag = self.session.connectedTag;
    if (tag == NULL) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorCancelNFCSession userInfo:@{@"message": @"Tag reader session was invalidated"}];
        return NULL;
    }
    BOOL needWait = [NSUserDefaults.standardUserDefaults boolForKey:[[NSString alloc] initWithData:tag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
    if (needWait) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: TapProtocolException::RATE_LIMIT userInfo:@{@"message": @"Tapsigner need to wait"}];
    }
    auto transport = MakeDefaultTransportIOS([tag](const APDURequest &req) {
        Bytes bytes = {req.cla, req.ins, req.p1, req.p2};
        NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes.data() length:bytes.size() * sizeof(unsigned char)];
        [data appendBytes:req.data.data() length:req.data.size() * sizeof(unsigned char)];
        NFCISO7816APDU *apdu = [[NFCISO7816APDU alloc] initWithData:data];
        
        __block auto response = APDUResponse();
        __block NSError *storedError;
        
        if (tag.asNFCISO7816Tag != nil) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [tag.asNFCISO7816Tag sendCommandAPDU:apdu completionHandler:^(NSData * _Nonnull responseData, uint8_t sw1, uint8_t sw2, NSError * _Nullable error) {
                storedError = error;
                const unsigned char *dataArray = (unsigned char *)responseData.bytes;
                const size_t count = responseData.length / sizeof(unsigned char);
                Bytes responseBytes(dataArray, dataArray + count);
                response.data = responseBytes;
                response.sw1 = sw1;
                response.sw2 = sw2;
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (storedError != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"Tag connection lost [%ld]", storedError.code];
                throw TapProtocolException(TapProtocolException::TAG_LOST, [errorMessage UTF8String]);
            }
        } else {
            throw TapProtocolException(TapProtocolException::INVALID_DEVICE_TYPE, [@"This NFC command is not supported yet." UTF8String]);
        }
        
        return response;
    });
    auto card = nunchukManager->nu->CreateTapsigner(std::move(transport));
    return card;
}

- (ObjTapsignerStatus *)needSetupWithError:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        auto status = nunchukManager->nu->GetTapsignerStatus(card.get());
        [self invalidateSessionWithError:NULL];
        return [[ObjTapsignerStatus alloc] initWithTapsignerStatus:&status];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)setupTapsignerWithCurrentCVC:(NSString *)currentCVC newCVC:(NSString *)newCVC derivationPath:(NSString *)derivationPath chainCode:(NSString *)chainCode keyName:(NSString *)keyName error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        std::function<bool(int)> callback = [&self](int percent) {
            [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
            return true;
        };
        TapsignerStatus status;
        if (card->NeedSetup()) {
            status = nunchukManager->nu->SetupTapsigner(card.get(), [currentCVC UTF8String], [newCVC UTF8String], {}, [chainCode UTF8String]);
        } else {
            status = nunchukManager->nu->BackupTapsigner(card.get(), [newCVC UTF8String]);
        }
        const std::vector<unsigned char> &data = status.get_backup_data();
        NSMutableArray *masterSigners = [self getMasterSigners:NULL];
        [masterSigners filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable obj, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((ObjMasterSigner *)obj).signerType == NFC;
        }]];
        NSString *name = [NSString stringWithString:keyName];
        if (name.length == 0) {
            name = [NSString stringWithFormat:@"NFC key %lu", (unsigned long)masterSigners.count + 1];
        }
        MasterSigner masterSigner = nunchukManager->nu->CreateTapsignerMasterSigner(card.get(), [newCVC UTF8String], [name UTF8String], callback);
        ObjMasterSigner *objMasterSigner = [[ObjMasterSigner alloc] initWithMasterSigner:&masterSigner];
        NSString *cardId = [NSString stringWithUTF8String: status.get_card_ident().c_str()];
        [self invalidateSessionWithError:NULL];
        return @{@"data": [[NSData alloc] initWithBytes:data.data() length:sizeof(unsigned char) * data.size()], @"filename": [NSString stringWithFormat: @"backup.%.0f.%@.aes", [[NSDate date] timeIntervalSince1970], cardId], @"masterSigner": objMasterSigner};
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        return NULL;
    }
}

- (NSNumber *)didCreateTapsignerMasterSignerWithError:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        TapsignerStatus status = nunchukManager->nu->GetTapsignerStatus(card.get());
        NSNumber *result = [NSNumber numberWithBool: status.is_master_signer()];
        [self invalidateSessionWithError:NULL];
        return result;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjMasterSigner *_Nullable)createTapsignerMasterSignerWithName:(NSString *_Nonnull)name cvc:(NSString *)cvc replace:(BOOL)replace error:(NSError **)error {
    std::function<bool(int)> callback = [&self](int percent) {
        [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
        return true;
    };
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        MasterSigner masterSigner = nunchukManager->nu->CreateTapsignerMasterSigner(card.get(), [cvc UTF8String], [name UTF8String], callback, false, replace);
        [self invalidateSessionWithError:NULL];
        return [[ObjMasterSigner alloc] initWithMasterSigner:&masterSigner];
    } catch (const BaseException& exception) {
        if (exception.code() == StorageException::SIGNER_EXISTS) {
            [self invalidateSessionWithError:*error];
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorSignerExist userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
            return NULL;
        }
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)createTapsignerWithName:(NSString *)name cvc:(NSString *)cvc error:(NSError **)error {
    std::function<bool(int)> callback = [&self](int percent) {
        [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
        return true;
    };
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        std::function<bool(int)> callback = [&self](int percent) {
            [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
            return true;
        };
        TapsignerStatus status;
        if (card->NeedSetup()) {
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": @"PIN is incorrect"}];
            return NULL;
        } else {
            status = nunchukManager->nu->BackupTapsigner(card.get(), [cvc UTF8String]);
        }
        const std::vector<unsigned char> &data = status.get_backup_data();
        NSArray *allKeys = [self getMasterSigners:nil];
        MasterSigner masterSigner = nunchukManager->nu->CreateTapsignerMasterSigner(card.get(), [cvc UTF8String], [name UTF8String], callback);
        ObjMasterSigner *objMasterSigner = [[ObjMasterSigner alloc] initWithMasterSigner:&masterSigner];
        BOOL isExisted = false;
        for (ObjMasterSigner *key in allKeys) {
            if (objMasterSigner.signerId == key.signerId) {
                isExisted = true;
            }
        }
        [self invalidateSessionWithError:NULL];
        return @{@"data": [[NSData alloc] initWithBytes:data.data() length:sizeof(unsigned char) * data.size()], @"masterSigner": objMasterSigner, @"existed": [NSNumber numberWithBool:isExisted]};
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)signTapsignerTransactionWithCVC:(NSString *_Nonnull)cvc walletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        auto tx = nunchukManager->nu->SignTapsignerTransaction(card.get(), [cvc UTF8String], [walletId UTF8String], [txId UTF8String]);
        [self invalidateSessionWithError:NULL];
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        return NULL;
    }
}

- (ObjNunchukMatrixEvent *)signTapsignerTransactionWithInitEventId:(NSString *_Nonnull)initEventId cvc:(NSString *_Nonnull)cvc walletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError **)error {
    try {
        if (nunchukManager->nuMatrix) {
            std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
            if (*error != NULL) {
                if ((*error).code == TapProtocolException::RATE_LIMIT) {
                    if (![self waitTapsigner:card.get() error:error]) {
                        [self invalidateSessionWithError:*error];
                        return NULL;
                    }
                } else {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            }
            auto event = nunchukManager->nuMatrix->SignTapsignerTransaction(nunchukManager->nu, [initEventId UTF8String], card.get(), [cvc UTF8String]);
            [self invalidateSessionWithError:NULL];
            return [[ObjNunchukMatrixEvent alloc] initWithMatrixEvent:event];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)signTapsignerTransactionWith:(NSString *)cvc psbt:(NSString *)psbt error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        auto signedPSBT = Utils::SignPsbt(card.get(), [cvc UTF8String], [psbt UTF8String]);
        [self invalidateSessionWithError:NULL];
        return [NSString stringWithUTF8String: signedPSBT.c_str()];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)changeCVC:(NSString *)currentCVC newCVC:(NSString *)newCVC masterSignerId:(NSString *)masterSignerId error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NO;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NO;
            }
        }
        BOOL result = nunchukManager->nu->ChangeTapsignerCVC(card.get(), [currentCVC UTF8String], [newCVC UTF8String], [masterSignerId UTF8String]);
        [self invalidateSessionWithError:NULL];
        return result;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)backupTapsignerWithCVC:(NSString *)cvc masterSignerId:(NSString *)masterSignerId error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        TapsignerStatus status = nunchukManager->nu->BackupTapsigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String]);
        NSString *cardId = [NSString stringWithUTF8String: status.get_card_ident().c_str()];
        std::vector<unsigned char> data = status.get_backup_data();
        [self invalidateSessionWithError:NULL];
        return @{@"data": [[NSData alloc] initWithBytes:data.data() length:sizeof(unsigned char) * data.size()], @"filename": [NSString stringWithFormat: @"backup.%.0f.%@.aes", [[NSDate date] timeIntervalSince1970], cardId]};
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)healthCheckTapsignerMasterSignerWithCVC:(NSString *)cvc fingerprint:(NSString *)fingerprint message:(NSString *)message path:(NSString *)path signature:(NSString *)signature error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NO;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NO;
            }
        }
        std::string cMessage([message UTF8String]);
        std::string cSignature([signature UTF8String]);
        std::string cPath([path UTF8String]);
        auto status = nunchukManager->nu->HealthCheckTapsignerMasterSigner(card.get(), [cvc UTF8String], [fingerprint UTF8String], cMessage, cSignature, cPath);
        KeyHealthStatus keyHealthStatus = [self parseHealthStatus:status];
        [self invalidateSessionWithError:NULL];
        if (keyHealthStatus == SUCCESS) {
            return YES;
        } else {
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [self healthStatusToString:keyHealthStatus]}];
            return NO;
        }
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)waitTapsigner:(Tapsigner*)card error:(NSError **)error {
    try {
        auto status = nunchukManager->nu->WaitTapsigner(card, [&self](int percent){
            [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
            return YES;
        });
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:[[NSString alloc] initWithData:self.session.connectedTag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
        return YES;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)cacheTapsignerMasterSignerXPubWithCVC:(NSString *)cvc masterSignerId:(NSString *)masterSignerId error:(NSError * _Nullable __autoreleasing *)error {
    std::function<bool(int)> callback = [&self](int percent) {
        [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
        return true;
    };
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NO;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NO;
            }
        }
        nunchukManager->nu->CacheTapsignerMasterSignerXPub(card.get(), [cvc UTF8String], [masterSignerId UTF8String], callback);
        [self invalidateSessionWithError:NULL];
        return YES;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTapsignerStatus *)getTapsignerStatusFromMasterSignerFrom:(NSString *)masterSignerId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tapsignerStatus = nunchukManager->nu->GetTapsignerStatusFromMasterSigner([masterSignerId UTF8String]);
        [self invalidateSessionWithError:NULL];
        return [[ObjTapsignerStatus alloc] initWithTapsignerStatus:&tapsignerStatus];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)generateRandomChainCode:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto chainCode = Utils::GenerateRandomChainCode();
        return [NSString stringWithUTF8String:chainCode.c_str()];
    } catch (const BaseException& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjMasterSigner *)importTapsignerMasterSigner:(NSString *)filePath key:(NSString *)backupKey error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::function<bool(int)> callback = [](int percent) {
            return true;
        };
        NSMutableArray *masterSigners = [self getMasterSigners:NULL];
        [masterSigners filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable obj, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ((ObjMasterSigner *)obj).signerType == NFC;
        }]];
        MasterSigner masterSigner = nunchukManager->nu->ImportTapsignerMasterSigner([filePath UTF8String], [backupKey UTF8String], [[NSString stringWithFormat:@"NFC key %lu", (unsigned long)masterSigners.count + 1] UTF8String], callback);
        return [[ObjMasterSigner alloc] initWithMasterSigner:&masterSigner];
    } catch (const BaseException& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)cacheDefaultTapsignerMasterSignerXPubWithCVC:(NSString *)cvc masterSignerId:(NSString *)masterSignerId error:(NSError * _Nullable __autoreleasing *)error {
    std::function<bool(int)> callback = [&self](int percent) {
        [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
        return true;
    };
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NO;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NO;
            }
        }
        nunchukManager->nu->CacheDefaultTapsignerMasterSignerXPub(card.get(), [cvc UTF8String], [masterSignerId UTF8String], callback);
        [self invalidateSessionWithError:NULL];
        return YES;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSError *)handleNFCException:(const BaseException&) exception {
    if (exception.code() == TapProtocolException::RATE_LIMIT) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:[[NSString alloc] initWithData:self.session.connectedTag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
    }
    NSError *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
    [self invalidateSessionWithError:error];
    return error;
}

- (NSString *)healthStatusToString:(KeyHealthStatus)status {
    switch (status) {
        case SUCCESS:
            return @"SUCCESS";
        case FINGERPRINT_NOT_MATCHED:
            return @"FINGERPRINT_NOT_MATCHED";
        case NO_SIGNATURE:
            return @"NO_SIGNATURE";
        case SIGNATURE_INVALID:
            return @"SIGNATURE_INVALID";
        case KEY_NOT_MATCHED:
            return @"KEY_NOT_MATCHED";
    }
}

- (BOOL)verifyTapsignerBackupWithData:(NSString *)backupBase64 password:(NSString *)password keyId:(NSString *)keyId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:backupBase64 options:0];
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        std::vector<unsigned char> backupData(dataArray, dataArray + count);
        nunchukManager->nu->VerifyTapsignerBackup(backupData, [password UTF8String], [keyId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)verifyColdCardBackupWithData:(NSString *)backupBase64 password:(NSString *)password keyId:(NSString *)keyId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:backupBase64 options:0];
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        std::vector<unsigned char> backupData(dataArray, dataArray + count);
        nunchukManager->nu->VerifyColdcardBackup(backupData, [password UTF8String], [keyId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)syncAssistedWallet:(ObjAssistedWallet *)wallet error:(NSError * _Nullable __autoreleasing *)error {
    try {
        BOOL shouldSyncKey = ![wallet.status isEqualToString:@"REPLACED"];
        NSMutableDictionary *isNew = [NSMutableDictionary new];
        if (shouldSyncKey) {
            for (ObjKeyInfo *key in wallet.signers) {
                std::pair<int, int> externalInternalIndex(0, 1);
                BOOL hasSigner = nunchukManager->nu->HasSigner(SingleSigner([key.name UTF8String], [key.xpub UTF8String], [key.pubkey UTF8String], [key.derivationPath UTF8String], externalInternalIndex, [key.xfp UTF8String], std::time(nullptr)));
                [isNew setObject:[NSNumber numberWithBool:hasSigner] forKey:key.xfp];
            }
        }
        if (!nunchukManager->nu->HasWallet([wallet.localId UTF8String])) {
            if (shouldSyncKey) {
                for (ObjKeyInfo *key in wallet.signers) {
                    BOOL hasSigner = [[isNew objectForKey:key.xfp] boolValue];
                    if (key.tapsigner != NULL) {
                        nunchukManager->nu->AddTapsigner([key.tapsigner.cardId UTF8String], [key.xfp UTF8String], [key.name UTF8String], [key.tapsigner.version UTF8String], key.tapsigner.birthHeight, key.tapsigner.isTestnet);
                    } else {
                        if (!hasSigner) {
                            SingleSigner signer = nunchukManager->nu->CreateSigner([key.name UTF8String], [key.xpub UTF8String], [key.pubkey UTF8String], [key.derivationPath UTF8String], [key.xfp UTF8String], [self parseObjCSignerType:key.type]);
                            signer.set_visible(key.isVisible);
                            nunchukManager->nu->UpdateRemoteSigner(signer);
                        }
                    }
                }
            }
            auto w = Utils::ParseWalletDescriptor([wallet.bsms UTF8String]);
            w.set_name([wallet.name UTF8String]);
            w.set_description([wallet.desc UTF8String]);
            nunchukManager->nu->CreateWallet(w, true);
        }
        
        auto w = nunchukManager->nu->GetWallet([wallet.localId UTF8String]);
        nunchukManager->updateWalletName([wallet.localId UTF8String], [wallet.name UTF8String]);
        if (shouldSyncKey) {
            auto localSigners = w.get_signers();
            for (ObjKeyInfo *key in wallet.signers) {
                auto localSigner = std::find_if(localSigners.begin(), localSigners.end(), [&](const SingleSigner &local) {
                    return local.get_master_fingerprint() == [key.xfp UTF8String];
                });
                BOOL hasSigner = [[isNew objectForKey:key.xfp] boolValue];
                if (localSigner->has_master_signer()) {
                    MasterSigner m = nunchukManager->nu->GetMasterSigner(localSigner->get_master_signer_id());
                    if (key.tags.count > 0) {
                        std::vector<SignerTag> tags;
                        for (NSString *tag in key.tags) {
                            tags.push_back(SignerTagFromStr([tag UTF8String]));
                        }
                        m.set_tags(tags);
                    }
                    if (hasSigner) {
                        m.set_visible(key.isVisible || localSigner->is_visible());
                    } else {
                        m.set_visible(key.isVisible);
                    }
                    m.set_name([key.name UTF8String]);
                    nunchukManager->nu->UpdateMasterSigner(m);
                } else {
                    if (hasSigner) {
                        localSigner->set_visible(key.isVisible || localSigner->is_visible());
                    } else {
                        localSigner->set_visible(key.isVisible);
                    }
                    localSigner->set_name([key.name UTF8String]);
                    nunchukManager->nu->UpdateRemoteSigner(*localSigner);
                    for (NSString *tag in key.tags) {
                        [self addKeyTag:tag path:key.derivationPath masterFingerprint:key.xfp error:nil];
                    }
                }
            }
        }
        
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)addKey:(ObjKeyInfo *)key error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        BOOL hasSigner = nunchukManager->nu->HasSigner(SingleSigner([key.name UTF8String], [key.xpub UTF8String], [key.pubkey UTF8String], [key.derivationPath UTF8String], externalInternalIndex, [key.xfp UTF8String], std::time(nullptr)));
        if (key.tapsigner != NULL) {
            nunchukManager->nu->AddTapsigner([key.tapsigner.cardId UTF8String], [key.xfp UTF8String], [key.name UTF8String], [key.tapsigner.version UTF8String], key.tapsigner.birthHeight, key.tapsigner.isTestnet);
        } else {
            if (!hasSigner) {
                nunchukManager->nu->CreateSigner([key.name UTF8String], [key.xpub UTF8String], [key.pubkey UTF8String], [key.derivationPath UTF8String], [key.xfp UTF8String], [self parseObjCSignerType:key.type]);
            }
        }
        auto signers = nunchukManager->getSigners();
        auto localSigner = std::find_if(signers.begin(), signers.end(), [&](const SingleSigner &local) {
            return local.get_master_fingerprint() == [key.xfp UTF8String];
        });
        if (localSigner == signers.end()) {
            auto masterSigners = nunchukManager->nu->GetMasterSigners();
            auto masterSigner = std::find_if(masterSigners.begin(), masterSigners.end(), [&](const MasterSigner &local) {
                return local.get_id() == [key.xfp UTF8String];
            });
            if (masterSigner == masterSigners.end()) {
                
            } else {
                MasterSigner m = nunchukManager->nu->GetMasterSigner(masterSigner->get_id());
                if (key.tags.count > 0) {
                    std::vector<SignerTag> tags;
                    for (NSString *tag in key.tags) {
                        tags.push_back(SignerTagFromStr([tag UTF8String]));
                    }
                    m.set_tags(tags);
                }
                if (hasSigner) {
                    m.set_visible(key.isVisible || masterSigner->is_visible());
                } else {
                    m.set_visible(key.isVisible);
                }
                m.set_name([key.name UTF8String]);
                nunchukManager->nu->UpdateMasterSigner(m);
            }
        } else {
            if (localSigner->has_master_signer()) {
                MasterSigner m = nunchukManager->nu->GetMasterSigner(localSigner->get_master_signer_id());
                if (key.tags.count > 0) {
                    std::vector<SignerTag> tags;
                    for (NSString *tag in key.tags) {
                        tags.push_back(SignerTagFromStr([tag UTF8String]));
                    }
                    m.set_tags(tags);
                }
                if (hasSigner) {
                    m.set_visible(key.isVisible || localSigner->is_visible());
                } else {
                    m.set_visible(key.isVisible);
                }
                m.set_name([key.name UTF8String]);
                nunchukManager->nu->UpdateMasterSigner(m);
            } else {
                if (hasSigner) {
                    localSigner->set_visible(key.isVisible || localSigner->is_visible());
                } else {
                    localSigner->set_visible(key.isVisible);
                }
                localSigner->set_name([key.name UTF8String]);
                nunchukManager->nu->UpdateRemoteSigner(*localSigner);
                for (NSString *tag in key.tags) {
                    [self addKeyTag:tag path:key.derivationPath masterFingerprint:key.xfp error:nil];
                }
            }
        }
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjTransaction *)syncRemoteTransaction:(ObjRemoteTransaction *)transaction error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tx = nunchukManager->nu->GetTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String]);
        ObjTransaction *localTransaction = [[ObjTransaction alloc] initWithTransaction:&tx];
        return [self syncTransaction:transaction localTransaction:localTransaction error:error];
    } catch (const std::exception& exception) {
        return [self syncTransaction:transaction localTransaction:nil error:error];
    }
}

- (ObjTransaction *)syncTransaction:(ObjRemoteTransaction *)transaction localTransaction:(ObjTransaction *)localTransaction error:(NSError * _Nullable __autoreleasing *)error {
    try {
        if (transaction.type != nil && [transaction.type isEqualToString:@"SCHEDULED"]) {
            double currentTime = std::time(nullptr);
            if (transaction.broadcastTime > 0 && transaction.broadcastTime > currentTime) {
                nunchukManager->nu->UpdateTransactionSchedule([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], transaction.broadcastTime);
            }
        } else {
            nunchukManager->nu->UpdateTransactionSchedule([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], -1);
        }
        if (localTransaction != nil && transaction.replaceTxId.length > 0 && [transaction.replaceTxId isEqualToString:localTransaction.replaceTXid]) {
            nunchukManager->nu->ReplaceTransactionId([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], [transaction.replaceTxId UTF8String]);
        }
        
        if ([transaction.status isEqualToString:@"PENDING_CONFIRMATION"] ||
            [transaction.status isEqualToString:@"CONFIRMED"] ||
            [transaction.status isEqualToString:@"NETWORK_REJECTED"]) {
            nunchukManager->nu->ImportPsbt([transaction.localWalletId UTF8String], [transaction.psbt UTF8String]);
            nunchukManager->nu->UpdateTransactionMemo([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], [transaction.note UTF8String]);
            if (localTransaction != nil && [localTransaction.status isEqualToString:@"CONFIRMED"]) {
                auto tx = nunchukManager->nu->GetTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String]);
                return [[ObjTransaction alloc] initWithTransaction:&tx];
            } else {
                nunchukManager->nu->UpdateTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], [transaction.transactionId UTF8String], [transaction.hex UTF8String], [transaction.rejectMessage UTF8String]);
                auto tx = nunchukManager->nu->GetTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String]);
                return [[ObjTransaction alloc] initWithTransaction:&tx];
            }
        } else if ([transaction.status isEqualToString:@"READY_TO_BROADCAST"] ||
                   [transaction.status isEqualToString:@"PENDING_SIGNATURES"]) {
            nunchukManager->nu->ImportPsbt([transaction.localWalletId UTF8String], [transaction.psbt UTF8String]);
            nunchukManager->nu->UpdateTransactionMemo([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String], [transaction.note UTF8String]);
            auto tx = nunchukManager->nu->GetTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String]);
            return [[ObjTransaction alloc] initWithTransaction:&tx];
        } else if ([transaction.status isEqualToString:@"CANCELED"]) {
            nunchukManager->nu->DeleteTransaction([transaction.localWalletId UTF8String], [transaction.localTransactionId UTF8String]);
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)updateTransactionScheduleWithWalletId:(NSString *)walletId txId:(NSString *)txId broadcastTime:(double)broadcastTime error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->UpdateTransactionSchedule([walletId UTF8String], [txId UTF8String], broadcastTime);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

// MARK: - Satscard
- (std::unique_ptr<CKTapCard>)createCKTapCardWithError:(NSError **)error {
    self.session = [[NFCTagReaderSession alloc] initWithPollingOption:NFCPollingISO14443 | NFCPollingISO15693 | NFCPollingISO18092 delegate:self queue:nfcQueue];
    [self.session setAlertMessage:@"Put your device near the NFC key."];
    [self.session beginSession];
    semaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    id<NFCTag> tag = self.session.connectedTag;
    if (tag == NULL) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorCancelNFCSession userInfo:@{@"message": @"Tag reader session was invalidated"}];
        
        return NULL;
    }
    if (tag.asNFCMiFareTag != nil) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorShouldHandleAsPortal userInfo:@{@"message": @"Should handle as Portal device"}];
        return NULL;
    }
    BOOL needWait = [NSUserDefaults.standardUserDefaults boolForKey:[[NSString alloc] initWithData:tag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
    if (needWait) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: TapProtocolException::RATE_LIMIT userInfo:@{@"message": @"Tapsigner need to wait"}];
    }
    auto transport = MakeDefaultTransportIOS([tag](const APDURequest &req) {
        Bytes bytes = {req.cla, req.ins, req.p1, req.p2};
        NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes.data() length:bytes.size() * sizeof(unsigned char)];
        [data appendBytes:req.data.data() length:req.data.size() * sizeof(unsigned char)];
        NFCISO7816APDU *apdu = [[NFCISO7816APDU alloc] initWithData:data];
        
        __block auto response = APDUResponse();
        __block NSError *storedError;
        if (tag.asNFCISO7816Tag != nil) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [tag.asNFCISO7816Tag sendCommandAPDU:apdu completionHandler:^(NSData * _Nonnull responseData, uint8_t sw1, uint8_t sw2, NSError * _Nullable error) {
                storedError = error;
                const unsigned char *dataArray = (unsigned char *)responseData.bytes;
                const size_t count = responseData.length / sizeof(unsigned char);
                Bytes responseBytes(dataArray, dataArray + count);
                response.data = responseBytes;
                response.sw1 = sw1;
                response.sw2 = sw2;
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (storedError != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"Tag connection lost [%ld]", storedError.code];
                throw TapProtocolException(TapProtocolException::TAG_LOST, [errorMessage UTF8String]);
            }
        } else {
            throw TapProtocolException(TapProtocolException::INVALID_DEVICE_TYPE, [@"This NFC command is not supported yet." UTF8String]);
        }
        return response;
    });
    auto card = nunchukManager->nu->CreateCKTapCard(std::move(transport));
    return card;
}

- (std::unique_ptr<Satscard>)createSatscardWithError:(NSError **)error {
    self.session = [[NFCTagReaderSession alloc] initWithPollingOption:NFCPollingISO14443 | NFCPollingISO15693 | NFCPollingISO18092 delegate:self queue:nfcQueue];
    [self.session setAlertMessage:@"Put your device near the NFC key."];
    [self.session beginSession];
    semaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    id<NFCTag> tag = self.session.connectedTag;
    if (tag == NULL) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorCancelNFCSession userInfo:@{@"message": @"Tag reader session was invalidated"}];
        return NULL;
    }
    BOOL needWait = [NSUserDefaults.standardUserDefaults boolForKey:[[NSString alloc] initWithData:tag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
    if (needWait) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: TapProtocolException::RATE_LIMIT userInfo:@{@"message": @"Tapsigner need to wait"}];
    }
    auto transport = MakeDefaultTransportIOS([tag](const APDURequest &req) {
        Bytes bytes = {req.cla, req.ins, req.p1, req.p2};
        NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes.data() length:bytes.size() * sizeof(unsigned char)];
        [data appendBytes:req.data.data() length:req.data.size() * sizeof(unsigned char)];
        NFCISO7816APDU *apdu = [[NFCISO7816APDU alloc] initWithData:data];
        
        __block auto response = APDUResponse();
        __block NSError *storedError;
        if (tag.asNFCISO7816Tag != nil) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [tag.asNFCISO7816Tag sendCommandAPDU:apdu completionHandler:^(NSData * _Nonnull responseData, uint8_t sw1, uint8_t sw2, NSError * _Nullable error) {
                storedError = error;
                const unsigned char *dataArray = (unsigned char *)responseData.bytes;
                const size_t count = responseData.length / sizeof(unsigned char);
                Bytes responseBytes(dataArray, dataArray + count);
                response.data = responseBytes;
                response.sw1 = sw1;
                response.sw2 = sw2;
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (storedError != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"Tag connection lost [%ld]", storedError.code];
                throw TapProtocolException(TapProtocolException::TAG_LOST, [errorMessage UTF8String]);
            }
        } else {
            throw TapProtocolException(TapProtocolException::INVALID_DEVICE_TYPE, [@"This NFC command is not supported yet." UTF8String]);
        }
        return response;
    });
    auto card = nunchukManager->nu->CreateSatscard(std::move(transport));
    return card;
}

- (ObjTapCardResult *)scanNFCCardWithError:(NSError **)error {
    try {
        std::unique_ptr<CKTapCard> card = [self createCKTapCardWithError:error];
        std::unique_ptr<Tapsigner> tapsigner;
        std::unique_ptr<Satscard> satscard;
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (card.get()->IsTapsigner()) {
                    tapsigner = tap_protocol::ToTapsigner(std::move(*card));
                } else {
                    satscard = tap_protocol::ToSatscard(std::move(*card));
                }
                if (tapsigner != nullptr) {
                    if (![self waitTapsigner:tapsigner.get() error:error]) {
                        [self invalidateSessionWithError:*error];
                        return NULL;
                    }
                } else {
                    if (![self waitSatscard:satscard.get() error:error]) {
                        [self invalidateSessionWithError:*error];
                        return NULL;
                    }
                }
            } else if ((*error).code == NunchukSDKErrorShouldHandleAsPortal) {
                ObjTapCardResult *result = [[ObjTapCardResult alloc] init];
                result.isPortal = YES;
                [self invalidateSessionWithError:NULL];
                return result;
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        } else {
            if (card.get()->IsTapsigner()) {
                tapsigner = tap_protocol::ToTapsigner(std::move(*card));
            } else {
                satscard = tap_protocol::ToSatscard(std::move(*card));
            }
        }
        ObjTapCardResult *result = [[ObjTapCardResult alloc] init];
        if (tapsigner != nullptr) {
            // Tapsigner
            auto tapsignerStatus = nunchukManager->nu->GetTapsignerStatus(tapsigner.get());
            result.tapsignerStatus = [[ObjTapsignerStatus alloc] initWithTapsignerStatus:&tapsignerStatus];
            result.isTapsigner = YES;
        } else {
            // Satscard
            auto satscardStatus = nunchukManager->nu->GetSatscardStatus(satscard.get());
            result.satscardStatus = [[ObjSatscardStatus alloc] initWithSatscardStatus:&satscardStatus];
            result.isTapsigner = NO;
        }
        [self invalidateSessionWithError:NULL];
        return result;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSatscardStatus *)getSatscardStatusWithError:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Satscard> card = [self createSatscardWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitSatscard:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        auto satscardStatus = nunchukManager->nu->GetSatscardStatus(card.get());
        [self invalidateSessionWithError:NULL];
        return [[ObjSatscardStatus alloc] initWithSatscardStatus:&satscardStatus];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSatscardStatus *)setupSatscardWithCurrenctCVC:(NSString *)currentCVC chainCode:(NSString *)chainCode error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Satscard> card = [self createSatscardWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitSatscard:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        auto satscardStatus = nunchukManager->nu->SetupSatscard(card.get(), [currentCVC UTF8String]);
        [self invalidateSessionWithError:NULL];
        return [[ObjSatscardStatus alloc] initWithSatscardStatus:&satscardStatus];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSatscardSlot *)unsealSatscardWithCurrentCVC:(NSString *)currentCVC slot:(ObjSatscardSlot *)slot error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::unique_ptr<Satscard> card = [self createSatscardWithError:outError];
        if (*outError != NULL) {
            if ((*outError).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitSatscard:card.get() error:outError]) {
                    [self invalidateSessionWithError:*outError];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*outError];
                return NULL;
            }
        }
        auto cSlot = nunchukManager->nu->UnsealSatscard(card.get(), [currentCVC UTF8String], [slot toSatscardSlot]);
        [self invalidateSessionWithError:NULL];
        return [[ObjSatscardSlot alloc] initWithSatscardSlot:&cSlot];
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*outError];
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSatscardSlot *)fetchSatscardSlotUTXOs:(ObjSatscardSlot *)slot error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto satscardSlot = nunchukManager->nu->FetchSatscardSlotUTXOs([slot toSatscardSlot]);
        return [[ObjSatscardSlot alloc] initWithSatscardSlot:&satscardSlot];
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<ObjSatscardSlot *> *)getSatscardSlotsKeyWithCurrentCVC:(NSString *)currentCVC slots:(NSArray<ObjSatscardSlot *> *)slots error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::unique_ptr<Satscard> card = [self createSatscardWithError:outError];
        if (*outError != NULL) {
            if ((*outError).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitSatscard:card.get() error:outError]) {
                    [self invalidateSessionWithError:*outError];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*outError];
                return NULL;
            }
        }
        NSMutableArray *objSlots = [[NSMutableArray alloc] init];
        for (ObjSatscardSlot *slot in slots) {
            auto satscardSlot = nunchukManager->nu->GetSatscardSlotKey(card.get(), [currentCVC UTF8String], [slot toSatscardSlot]);
            [objSlots addObject:[[ObjSatscardSlot alloc] initWithSatscardSlot:&satscardSlot]];
        }
        [self invalidateSessionWithError:NULL];
        return objSlots;
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*outError];
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction*) sweepSatscardSlot:(ObjSatscardSlot *)slot address:(NSString *)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto transaction = nunchukManager->nu->SweepSatscardSlot([slot toSatscardSlot], [address UTF8String], feeRate);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)SweepSatscardSlots:(NSArray<ObjSatscardSlot *> *)slots address:(NSString *)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SatscardSlot> cSlots;
        for (ObjSatscardSlot *slot in slots) {
            cSlots.push_back([slot toSatscardSlot]);
        }
        auto transaction = nunchukManager->nu->SweepSatscardSlots(cSlots, [address UTF8String], feeRate);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)createSatscardSlotsTransactionWithSlots:(NSArray<ObjSatscardSlot *> *)slots address:(NSString *)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SatscardSlot> cSlots;
        for (ObjSatscardSlot *slot in slots) {
            cSlots.push_back([slot toSatscardSlot]);
        }
        auto transaction = nunchukManager->nu->CreateSatscardSlotsTransaction(cSlots, [address UTF8String], feeRate);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)waitSatscard:(Satscard*)card error:(NSError **)error {
    try {
        auto status = nunchukManager->nu->WaitSatscard(card, [&self](int percent){
            [self.session setAlertMessage:[NSString stringWithFormat:@"Please wait. Command in progress (%d%%).\nKeep holding the key near the device until it's finished.", percent]];
            return YES;
        });
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:[[NSString alloc] initWithData:self.session.connectedTag.asNFCISO7816Tag.identifier encoding:NSASCIIStringEncoding]];
        return YES;
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjTransaction *)fetchTransactionWithTxId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tx = nunchukManager->nu->FetchTransaction([txId UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSatscardStatus *_Nullable)unsealAndSetupSatscardWithCurrenctCVC:(NSString *_Nonnull)currentCVC chainCode:(NSString *_Nullable)chainCode slot:(ObjSatscardSlot *_Nonnull)slot error:(NSError *_Nullable*_Nullable)outError {
    try {
        std::unique_ptr<Satscard> card = [self createSatscardWithError:outError];
        if (*outError != NULL) {
            if ((*outError).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitSatscard:card.get() error:outError]) {
                    [self invalidateSessionWithError:*outError];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*outError];
                return NULL;
            }
        }
        
        auto cSlot = nunchukManager->nu->UnsealSatscard(card.get(), [currentCVC UTF8String], [slot toSatscardSlot]);
        
        auto satscardStatus = nunchukManager->nu->SetupSatscard(card.get(), [currentCVC UTF8String]);
        
        [self invalidateSessionWithError:NULL];
        
        return [[ObjSatscardStatus alloc] initWithSatscardStatus:&satscardStatus];
        
    } catch (const BaseException& exception) {
        *outError = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*outError];
        *outError = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)getDefaultSignerFromMasterSigner:(NSString *)masterSignerId walletType:(NSString *)walletType addressType:(NSString *)addressType error:(NSError * _Nullable __autoreleasing *)error {
    AddressType cAddressType = [self addressTypeFromString:addressType];
    WalletType cWalletType = [self walletTypeFromString:walletType];
    try {
        auto singleSigner = nunchukManager->nu->GetDefaultSignerFromMasterSigner([masterSignerId UTF8String], cWalletType, cAddressType);
        return [[ObjSingleSigner alloc] initWithSigner:&singleSigner];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)getSignerFromMasterSigner:(NSString *)masterSignerId path:(NSString *)path error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto singleSigner = nunchukManager->nu->GetSignerFromMasterSigner([masterSignerId UTF8String], [path UTF8String]);
        return [[ObjSingleSigner alloc] initWithSigner:&singleSigner];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)getUnusedSignerFromMasterSigner:(NSString *)masterSignerId walletType:(NSString *)walletType addressType:(NSString *)addressType error:(NSError * _Nullable __autoreleasing *)error {
    AddressType cAddressType = [self addressTypeFromString:addressType];
    WalletType cWalletType = [self walletTypeFromString:walletType];
    try {
        auto singleSigner = nunchukManager->nu->GetUnusedSignerFromMasterSigner([masterSignerId UTF8String], cWalletType, cAddressType);
        return [[ObjSingleSigner alloc] initWithSigner:&singleSigner];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

// MARK: - ColdCard

- (NSArray *)parseJsonSignerWithJson:(NSString *)json error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto signers = nunchukManager->nu->ParseJSONSigners([json UTF8String]);
        NSMutableArray *remoteSigners = [[NSMutableArray alloc] init];
        for (auto signer: signers) {
            ObjSingleSigner *remoteSigner = [[ObjSingleSigner alloc] initWithSigner:&signer];
            [remoteSigners addObject:remoteSigner];
        }
        return remoteSigners;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)createColdCardNFCKey:(NSString *)name xpub:(NSString *)xPub publicKey:(NSString *)publicKey path:(NSString *)path fingerprint:(NSString *)fingerPrint error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto signer = nunchukManager->nu->CreateSigner([name UTF8String], [xPub UTF8String], [publicKey UTF8String], [path UTF8String], [fingerPrint UTF8String], SignerType::COLDCARD_NFC, {}, true);
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getColdCardExportData:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        if (wallet.get_wallet_type() == WalletType::MINISCRIPT) {
            return [NSString stringWithUTF8String:wallet.get_descriptor(DescriptorPath::EXTERNAL_INTERNAL).c_str()];
        } else {
            return [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(std::string([walletId UTF8String]), ExportFormat::COLDCARD).c_str()];
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getWalletExportData:(ObjWallet *)wallet format:(NunchukExportFormat)format error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner>signers;
        for (NSUInteger i = 0; i < wallet.signers.count; i++) {
            if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                signers.push_back(signer);
            }
        }
        AddressType addressType = [self addressTypeFromString: wallet.addressType];
        auto exportFormat = [self parseExportFormat:format];
        if (wallet.isMiniscriptWallet) {
            auto obj = Wallet([wallet.miniscript UTF8String], signers, addressType, wallet.m);
            return [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(obj, exportFormat).c_str()];
        } else {
            auto obj = Wallet([wallet.walletId UTF8String], [wallet.walletName UTF8String], wallet.m, wallet.n, signers, addressType, wallet.isEscrow, [wallet.createdAt timeIntervalSince1970]);
            return [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(obj, exportFormat).c_str()];
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ExportFormat)parseExportFormat:(NunchukExportFormat)format {
    switch (format) {
        case DB:
            return ExportFormat::DB;
        case DESCRIPTOR:
            return ExportFormat::DESCRIPTOR;
        case COLDCARD:
            return ExportFormat::COLDCARD;
        case COBO:
            return ExportFormat::COBO;
        case CSV:
            return ExportFormat::CSV;
        case BSMS:
            return ExportFormat::BSMS;
        case DESCRIPTOR_EXTERNAL_ALL:
            return ExportFormat::DESCRIPTOR_EXTERNAL_ALL;
        case DESCRIPTOR_EXTERNAL_INTERNAL:
            return ExportFormat::DESCRIPTOR_EXTERNAL_INTERNAL;
    }
}

- (ObjBSMSData *)getPortalBSMSData:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::string bsms = nunchukManager->nu->GetWalletExportData(std::string([walletId UTF8String]), ExportFormat::BSMS);
        auto bsmsData = Utils::ParseBSMSData(bsms);
        ObjBSMSData *result = [[ObjBSMSData alloc] init];
        result.version = [NSString stringWithUTF8String:bsmsData.version.c_str()];
        result.descriptor = [NSString stringWithUTF8String:bsmsData.descriptor.c_str()];
        result.pathRestriction = [NSString stringWithUTF8String:bsmsData.path_restrictions.c_str()];
        result.firstAddress = [NSString stringWithUTF8String:bsmsData.first_address.c_str()];
        return result;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getBSMSExportData:(NSString *)content error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto wallet = Utils::ParseWalletDescriptor([content UTF8String]);
        return [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(wallet, ExportFormat::BSMS).c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)createWallet:(ObjWallet *)wallet name:(NSString *)name error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner>remoteSigners;
        for(unsigned long i = 0; i < wallet.signers.count; i++) {
            if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                std::pair<int, int> externalInternalIndex(0, 1);
                if (rmSigner.externalInternalIndex != nil) {
                    externalInternalIndex.first = rmSigner.externalInternalIndex.first;
                    externalInternalIndex.second = rmSigner.externalInternalIndex.second;
                }
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), externalInternalIndex, std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                remoteSigners.push_back(signer);
            }
        }
        AddressType addressType = [self addressTypeFromString: wallet.addressType];
        auto wl = Wallet([wallet.walletId UTF8String], wallet.m, wallet.n, remoteSigners, addressType, wallet.isEscrow, [wallet.createdAt timeIntervalSince1970]);
        auto newWallet = nunchukManager->nu->CreateWallet(wl, true);
        newWallet.set_name([name UTF8String]);
        nunchukManager->nu->UpdateWallet(newWallet);
        return [[ObjWallet alloc] initWithWallet:&newWallet];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

-(ObjWallet *)createMiniscriptWallet:(NSString *)name miniscript:(NSString *)miniscript signers:(NSDictionary<NSString *, ObjSingleSigner *> *_Nonnull)signers addressType:(NSString *)addressType description:(NSString *)description allowUsedSigner:(BOOL)allowUsedSigner decoyPin:(NSString *)decoyPin error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::map<std::string, SingleSigner> signerMap;
        for (NSString *key in signers) {
            id obj = [signers objectForKey:key];
            ObjSingleSigner *remoteSigner = (ObjSingleSigner *)obj;
            std::pair<int, int> externalInternalIndex(0, 1);
            if (remoteSigner.externalInternalIndex != nil) {
                externalInternalIndex.first = remoteSigner.externalInternalIndex.first;
                externalInternalIndex.second = remoteSigner.externalInternalIndex.second;
            }
            auto cSigner = SingleSigner(std::string([remoteSigner.signerName UTF8String]), std::string([remoteSigner.xpub UTF8String]), std::string([remoteSigner.publicKey UTF8String]), std::string([remoteSigner.bip32Path UTF8String]), externalInternalIndex, std::string([remoteSigner.masterFingerPrint UTF8String]), false);
            cSigner.set_type([self parseObjCSignerType:remoteSigner.type]);
            signerMap[std::string([key UTF8String])] = cSigner;
        }
        
        AddressType address_type = [self addressTypeFromString:addressType];
        auto wallet = nunchukManager->nu->CreateMiniscriptWallet([name UTF8String],
                                                                 [miniscript UTF8String],
                                                                 signerMap,
                                                                 address_type,
                                                                 [description UTF8String],
                                                                 allowUsedSigner,
                                                                 [decoyPin UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getTransactionPSBT:(NSString *)transactionId walletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto transaction = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        return [NSString stringWithUTF8String:transaction.get_psbt().c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWallet *)parseWalletConfig:(NSString *)config chain:(ChainTypeEnum)chain error:(NSError **)error {
    try {
        Chain chainValue = Chain::MAIN;
        switch (chain) {
            case MAIN:
                chainValue = Chain::MAIN;
                break;
            case TESTNET:
                chainValue = Chain::TESTNET;
                break;
            case REGTEST:
                chainValue = Chain::REGTEST;
                break;
            case SIGNET:
                chainValue = Chain::SIGNET;
                break;
        }
        auto wallet = Utils::ParseWalletConfig(chainValue, [config UTF8String]);
        return [[ObjWallet alloc] initWithWallet:&wallet];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)parseJsonWallets:(NSString *)json error:(NSError **)error {
    try {
        NSMutableArray *array = [NSMutableArray new];
        auto wallets = nunchukManager->nu->ParseJSONWallets([json UTF8String]);
        for (auto wallet: wallets) {
            ObjWallet *obj = [[ObjWallet alloc] initWithWallet:&wallet];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)importRawTransaction:(NSString *)walletId rawData:(NSString *)rawData error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto transaction = nunchukManager->nu->ImportRawTransaction([walletId UTF8String], [rawData UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&transaction];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)healthCheckColdCard:(ObjSingleSigner *)signer message:(NSString *)message error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (signer.externalInternalIndex != nil) {
            externalInternalIndex.first = signer.externalInternalIndex.first;
            externalInternalIndex.second = signer.externalInternalIndex.second;
        }
        SingleSigner singleSigner = SingleSigner([signer.signerName UTF8String], [signer.xpub UTF8String], [signer.publicKey UTF8String], [signer.bip32Path UTF8String], externalInternalIndex, [signer.masterFingerPrint UTF8String], signer.lastHealthCheckTS);
        singleSigner.set_type([self parseObjCSignerType:signer.type]);
        BitcoinSignedMessage signedMessage = ParseBitcoinSignedMessage([message UTF8String]);
        HealthStatus status = nunchukManager->nu->HealthCheckSingleSigner(singleSigner, signedMessage.message, signedMessage.signature);
        if (status == nunchuk::HealthStatus::SUCCESS) {
            return YES;
        } else {
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [self healthCheckMessageFrom:status]}];
            return NO;
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)healthCheckMessageFrom:(HealthStatus)status {
    switch (status) {
        case nunchuk::HealthStatus::SUCCESS:
            return @"Success";
        case nunchuk::HealthStatus::FINGERPRINT_NOT_MATCHED:
            return @"Fingerprint does not match";
        case nunchuk::HealthStatus::NO_SIGNATURE:
            return @"No signature";
        case nunchuk::HealthStatus::SIGNATURE_INVALID:
            return @"Invalid signature";
        case nunchuk::HealthStatus::KEY_NOT_MATCHED:
            return @"Key does not match";
    }
}

// MARK: - NFC
- (void)invalidateSessionWithError:(NSError *_Nullable)error {
    // IMPORTANT: Setting an empty alert message first prevents the NFC error messages from being cut off.
    // This resolves UI issues with long error messages that would otherwise be truncated.
    [self.session setAlertMessage:@""];
    if (error == NULL) {
        [self.session invalidateSession];
    } else {
        NSString *errorMessage = error.userInfo[@"message"];
        if (errorMessage.length == 0) {
            errorMessage = error.localizedDescription;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.session invalidateSessionWithErrorMessage:errorMessage];
        });
    }
}

- (void)tagReaderSession:(NFCTagReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags {
    id<NFCTag> tag = [tags firstObject];
    [session connectToTag:tag completionHandler:^(NSError * _Nullable error) {
        if (error != NULL) {
            [session invalidateSessionWithErrorMessage:@"Unable to connect tag"];
            return;
        }
        dispatch_semaphore_signal(semaphore);
    }];
}

- (void)tagReaderSession:(nonnull NFCTagReaderSession *)session didInvalidateWithError:(nonnull NSError *)error {
    dispatch_semaphore_signal(semaphore);
}

- (void)tagReaderSessionDidBecomeActive:(NFCTagReaderSession *)session {
}

// MARK: - Premium
- (BOOL)verifyTapsignerBackupWithData:(NSString *)backupBase64 key:(NSString *)backupKey masterSignerId:(NSString *)masterSignerId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:backupBase64 options:0];
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        Bytes responseBytes(dataArray, dataArray + count);
        nunchukManager->nu->VerifyTapsignerBackup(responseBytes, [backupKey UTF8String], [masterSignerId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjMasterSigner *)importBackupKeyWithData:(NSString *)backupBase64 key:(NSString *)backupKey name:(NSString *)rawName error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::function<bool(int)> callback = [](int percent) {
            return true;
        };
        NSData *data = [[NSData alloc] initWithBase64EncodedString:backupBase64 options:0];
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        Bytes responseBytes(dataArray, dataArray + count);
        MasterSigner masterSigner = nunchukManager->nu->ImportBackupKey(responseBytes, [backupKey UTF8String], [rawName UTF8String], callback);
        return [[ObjMasterSigner alloc] initWithMasterSigner:&masterSigner];
    } catch (const BaseException& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)signHealthCheckMessageWithSingleSigner:(ObjSingleSigner *)singleSigner mesage:(NSString *)message error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (singleSigner.externalInternalIndex != nil) {
            externalInternalIndex.first = singleSigner.externalInternalIndex.first;
            externalInternalIndex.second = singleSigner.externalInternalIndex.second;
        }
        auto signer = SingleSigner(std::string([singleSigner.signerName UTF8String]), std::string([singleSigner.xpub UTF8String]), std::string([singleSigner.publicKey UTF8String]), std::string([singleSigner.bip32Path UTF8String]), externalInternalIndex, std::string([singleSigner.masterFingerPrint UTF8String]), false);
        signer.set_type([self parseObjCSignerType:singleSigner.type]);
        auto signature = nunchukManager->nu->SignHealthCheckMessage(signer, [message UTF8String]);
        return [NSString stringWithUTF8String:signature.c_str()];
    } catch (const BaseException& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)signHealthCheckMessageTapsignerWithSingleSigner:(ObjSingleSigner *)singleSigner mesage:(NSString *)message cvc:(NSString *)cvc error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        std::pair<int, int> externalInternalIndex(0, 1);
        if (singleSigner.externalInternalIndex != nil) {
            externalInternalIndex.first = singleSigner.externalInternalIndex.first;
            externalInternalIndex.second = singleSigner.externalInternalIndex.second;
        }
        auto signer = SingleSigner(std::string([singleSigner.signerName UTF8String]), std::string([singleSigner.xpub UTF8String]), std::string([singleSigner.publicKey UTF8String]), std::string([singleSigner.bip32Path UTF8String]), externalInternalIndex, std::string([singleSigner.masterFingerPrint UTF8String]), false);
        signer.set_type([self parseObjCSignerType:singleSigner.type]);
        auto signature = nunchukManager->nu->SignHealthCheckMessage(card.get(), [cvc UTF8String], signer, [message UTF8String]);
        [self invalidateSessionWithError:*error];
        return [NSString stringWithUTF8String:signature.c_str()];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)getHealthcheckDummyTxWithWallet:(NSString *)walletId body:(NSString *)body error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto wl = nunchukManager->nu->GetWallet([walletId UTF8String]);
        auto psbt = Utils::GetHealthCheckDummyTx(wl, [body UTF8String]);
        auto tx = Utils::DecodeDummyTx(wl, psbt);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)decodeDummyTxWithWallet:(NSString *)walletId psbt:(NSString *)psbt error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto wl = nunchukManager->nu->GetWallet([walletId UTF8String]);
        auto tx = Utils::DecodeDummyTx(wl, [psbt UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)decodeDummyTxWithData:(NSData *)data walletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto wl = nunchukManager->nu->GetWallet([walletId UTF8String]);
        
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        std::string psbt(dataArray, dataArray + count);
        auto tx = Utils::DecodeDummyTx(wl, psbt);
        return [[ObjTransaction alloc] initWithTransaction:&tx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)signClaimTransaction:(NSString *)masterSignerId psbt:(NSString *)psbt subAmount:(UInt64)subAmount fee:(UInt64)fee feeRate:(UInt64)feeRate error:(NSError * _Nullable __autoreleasing *)error {
    try {
        SingleSigner signer = nunchukManager->nu->GetDefaultSignerFromMasterSigner([masterSignerId UTF8String], WalletType::MULTI_SIG, AddressType::NATIVE_SEGWIT);
        std::vector<SingleSigner>signers;
        signers.push_back(signer);
        Wallet wallet = Wallet("", 1, 1, signers, AddressType::NATIVE_SEGWIT, false, 0, true);
        wallet.set_signers({signer});
        Transaction tx = Utils::DecodeTx(wallet, [psbt UTF8String], subAmount, fee, feeRate);
        Transaction signedTx = nunchukManager->nu->SignTransaction(wallet, tx, Device([masterSignerId UTF8String]));
        return [[ObjTransaction alloc] initWithTransaction:&signedTx];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)forceRefreshWalletWithWalletId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->ForceRefreshWallet([walletId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)addKeyTag:(NSString *)tag path:(NSString *)path masterFingerprint:(NSString *)masterFingerprint error:(NSError * _Nullable __autoreleasing *)error {
    try {
        if (![[NunchukLibUlti shared] isAirgapTypeTag:tag] && ![[NunchukLibUlti shared] isHardwareTypeTag:tag] && ![[NunchukLibUlti shared] isInheritanceTag:tag]) {
            return YES;
        }
        auto signers = nunchukManager->nu->GetRemoteSigners();
        auto sMasterFingerprint = [masterFingerprint UTF8String];
        auto sPath = [path UTF8String];
        for (auto &signer : signers) {
            if (signer.get_derivation_path().compare(sPath) == 0 && signer.get_master_fingerprint().compare(sMasterFingerprint) == 0) {
                NSMutableArray *currentTags = [NSMutableArray array];
                BOOL hasTag = NO;
                for (auto &stag : signer.get_tags()) {
                    NSString *tagStr = [NSString stringWithUTF8String:SignerTagToStr(stag).c_str()];
                    [currentTags addObject:tagStr];
                    if ([[NunchukLibUlti shared] isAirgapTypeTag:tagStr]) {
                        hasTag = YES;
                    }
                    if ([[NunchukLibUlti shared] isHardwareTypeTag:tagStr]) {
                        hasTag = YES;
                    }
                }
                if (!hasTag && ![currentTags containsObject:tag]) {
                    [currentTags addObject:tag];
                    
                    std::vector<SignerTag> sTags;
                    for (NSString *tag in currentTags) {
                        sTags.push_back(SignerTagFromStr([tag UTF8String]));
                    }
                    signer.set_tags(sTags);
                    nunchukManager->nu->UpdateRemoteSigner(signer);
                }
            }
        }
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSArray *)getCoins:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto outputs = nunchukManager->nu->GetUnspentOutputs([walletId UTF8String]);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &output : outputs) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&output];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getInputCoins:(NSString *)walletId transactionId:(NSString *)transactionId error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        auto tx = nunchukManager->nu->GetTransaction([walletId UTF8String], [transactionId UTF8String]);
        auto inputs = nunchukManager->nu->GetCoinsFromTxInputs([walletId UTF8String], tx.get_inputs());
        NSMutableArray *array = [NSMutableArray array];
        for (auto &input : inputs) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&input];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getCoinTags:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tags = nunchukManager->nu->GetCoinTags([walletId UTF8String]);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &tag : tags) {
            ObjCoinTag *obj = [[ObjCoinTag alloc] initWithCoinTag:&tag];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjCoinTag *)createCoinTag:(NSString *)walletId name:(NSString *)name color:(NSString *)color error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tag = nunchukManager->nu->CreateCoinTag([walletId UTF8String], [name UTF8String], [color UTF8String]);
        return [[ObjCoinTag alloc] initWithCoinTag:&tag];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)updateCoinTag:(NSString *)walletId tag:(ObjCoinTag *)tag error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto coinTag = CoinTag(tag.tagId, [tag.name UTF8String], [tag.color UTF8String]);
        return nunchukManager->nu->UpdateCoinTag([walletId UTF8String], coinTag);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)deleteCoinTag:(NSString *)walletId tagId:(int)tagId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->DeleteCoinTag([walletId UTF8String], tagId);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSArray *)getCoinCollections:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto collections = nunchukManager->nu->GetCoinCollections([walletId UTF8String]);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &collection : collections) {
            ObjCoinCollection *obj = [[ObjCoinCollection alloc] initWithCoinCollection:&collection];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjCoinCollection *)createCoinCollection:(NSString *)walletId name:(NSString *)name error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto collection = nunchukManager->nu->CreateCoinCollection([walletId UTF8String], [name UTF8String]);
        return [[ObjCoinCollection alloc] initWithCoinCollection:&collection];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)updateCoinCollection:(NSString *)walletId collection:(ObjCoinCollection *)collection applyToExistingCoins:(BOOL)applyToExistingCoins error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto coinCollection = CoinCollection(collection.collectionId, [collection.name UTF8String]);
        coinCollection.set_auto_lock(collection.autoLockEnabled);
        std::vector<int> addCoinsWithTagIds;
        if (collection.addCoinsWithoutTagEnabled) {
            addCoinsWithTagIds.push_back(-1);
        }
        for (NSNumber *tagId in collection.addCoinsWithTagIds) {
            addCoinsWithTagIds.push_back(tagId.intValue);
        }
        coinCollection.set_add_coins_with_tag(addCoinsWithTagIds);
        return nunchukManager->nu->UpdateCoinCollection([walletId UTF8String], coinCollection, applyToExistingCoins);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)deleteCoinCollection:(NSString *)walletId collectionId:(int)collectionId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->DeleteCoinCollection([walletId UTF8String], collectionId);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)lockCoin:(NSString *)walletId txId:(NSString *)txId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->LockCoin([walletId UTF8String], [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)unlockCoin:(NSString *)walletId txId:(NSString *)txId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->UnlockCoin([walletId UTF8String], [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)tagCoin:(NSString *)walletId txId:(NSString *)txId tagId:(int)tagId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->AddToCoinTag([walletId UTF8String], tagId, [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)untagCoin:(NSString *)walletId txId:(NSString *)txId tagId:(int)tagId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->RemoveFromCoinTag([walletId UTF8String], tagId, [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)addCoinToCollection:(NSString *)walletId txId:(NSString *)txId collectionId:(int)collectionId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->AddToCoinCollection([walletId UTF8String], collectionId, [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (BOOL)removeCoinFromCollection:(NSString *)walletId txId:(NSString *)txId collectionId:(int)collectionId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        return nunchukManager->nu->RemoveFromCoinCollection([walletId UTF8String], collectionId, [txId UTF8String], vout);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSArray *)getCoinsByTag:(NSString *)walletId tagId:(int)tagId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto coins = nunchukManager->nu->GetCoinByTag([walletId UTF8String], tagId);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &coin : coins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getCoinsInCollection:(NSString *)walletId collectionId:(int)collectionId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto coins = nunchukManager->nu->GetCoinInCollection([walletId UTF8String], collectionId);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &coin : coins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSNumber *)importCoinData:(NSString *)walletId data:(NSString *)data forceUpdate:(BOOL)forceUpdate error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto result = nunchukManager->nu->ImportCoinControlData([walletId UTF8String], [data UTF8String], forceUpdate);
        return [NSNumber numberWithBool:result];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)exportCoinData:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto data = nunchukManager->nu->ExportCoinControlData([walletId UTF8String]);
        return [NSString stringWithUTF8String:data.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)importBIP329:(NSString *)walletId data:(NSString *)data error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->ImportBIP329([walletId UTF8String], [data UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSString *)exportBIP329:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto data = nunchukManager->nu->ExportBIP329([walletId UTF8String]);
        return [NSString stringWithUTF8String:data.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getHealthCheckPath:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto path = nunchukManager->nu->GetHealthCheckPath();
        return [NSString stringWithUTF8String:path.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSignMessage *)signMessage:(NSString *)signerId path:(NSString *)path message:(NSString *)message error:(NSError * _Nullable __autoreleasing *)error {
    try {
        SingleSigner signer = nunchukManager->nu->GetSignerFromMasterSigner([signerId UTF8String], [path UTF8String]);
        NSString *address = [NSString stringWithUTF8String:nunchukManager->nu->GetSignerAddress(signer).c_str()];
        NSString *signature = [NSString stringWithUTF8String:nunchukManager->nu->SignMessage(signer, [message UTF8String]).c_str()];
        return [[ObjSignMessage alloc] initWithAddress:address signature:signature];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSignMessage *)signMessageTapsignerWithCVC:(NSString *)cvc signerId:(NSString *)signerId path:(NSString *)path message:(NSString *)message error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::unique_ptr<Tapsigner> tapsigner = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:tapsigner.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        SingleSigner signer = nunchukManager->nu->GetSignerFromTapsignerMasterSigner(tapsigner.get(), [cvc UTF8String], [signerId UTF8String], [path UTF8String]);
        NSString *address = [NSString stringWithUTF8String:nunchukManager->nu->GetSignerAddress(signer).c_str()];
        NSString *signature = [NSString stringWithUTF8String:nunchukManager->nu->SignTapsignerMessage(tapsigner.get(), [cvc UTF8String], signer, [message UTF8String]).c_str()];
        [self invalidateSessionWithError:NULL];
        return [[ObjSignMessage alloc] initWithAddress:address signature:signature];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getCoinAncestry:(NSString *)walletId txId:(NSString *)txId vout:(int)vout error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto ancestry = nunchukManager->nu->GetCoinAncestry([walletId UTF8String], [txId UTF8String], vout);
        NSMutableArray *array = [NSMutableArray array];
        for (auto &coins : ancestry) {
            NSMutableArray *coinArray = [NSMutableArray array];
            for (auto &coin : coins) {
                ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
                [coinArray addObject:obj];
            }
            [array addObject:coinArray];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)isAddressOfWallet:(NSString *)walletId address:(NSString *)address {
    try {
        return nunchukManager->nu->IsMyAddress([walletId UTF8String], [address UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSString *)getRawTransaction:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto raxTx = nunchukManager->nu->GetRawTransaction([walletId UTF8String], [txId UTF8String]);
        return [NSString stringWithUTF8String:raxTx.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)importDummyTx:(NSString *)data error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->ImportDummyTx([data UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSDictionary *)saveDummyTxToken:(NSString *)walletId txId:(NSString *)txId token:(NSString *)token error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tokens = nunchukManager->nu->SaveDummyTxRequestToken([walletId UTF8String], [txId UTF8String], [token UTF8String]);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (const auto& [key, status] : tokens) {
            [dict setObject:[NSNumber numberWithBool:status] forKey:[NSString stringWithUTF8String:key.c_str()]];
        }
        return dict;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)getDummyTxTokens:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tokens = nunchukManager->nu->GetDummyTxRequestToken([walletId UTF8String], [txId UTF8String]);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (const auto& [key, status] : tokens) {
            [dict setObject:[NSNumber numberWithBool:status] forKey:[NSString stringWithUTF8String:key.c_str()]];
        }
        return dict;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)getDummyTx:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto transaction = nunchukManager->nu->GetDummyTx([walletId UTF8String], [txId UTF8String]);
        return [[ObjTransaction alloc] initWithTransaction: &transaction];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)deleteDummyTx:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->DeleteDummyTx([walletId UTF8String], [txId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (NSArray *)getDummyTxsId:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto transactions = nunchukManager->nu->GetDummyTxs([walletId UTF8String]);
        NSMutableArray *array = [NSMutableArray new];
        for (const auto& [txId, tx] : transactions) {
            [array addObject:[NSString stringWithUTF8String:txId.c_str()]];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSNumber *_Nullable)getLastUsedSignerIndex:(NSString *)xfp walletType:(NSString *)walletType addressType:(NSString *)addressType error:(NSError * _Nullable __autoreleasing *)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        WalletType cWalletType = [self walletTypeFromString:walletType];
        auto index = nunchukManager->nu->GetLastUsedSignerIndex([xfp UTF8String], cWalletType, cAddressType);
        return [NSNumber numberWithInt:index];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return nil;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return nil;
    }
}

- (ObjSingleSigner *)getSignerWithIndex:(NSInteger)index xfp:(NSString *)xfp walletType:(NSString *)walletType addressType:(NSString *)addressType error:(NSError * _Nullable __autoreleasing *)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        WalletType cWalletType = [self walletTypeFromString:walletType];
        auto signer = nunchukManager->nu->GetSigner([xfp UTF8String], cWalletType, cAddressType, index);
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWalletData *)getBSMSAndFirstAddressWithQRs:(NSArray *)data chain:(ChainTypeEnum)chain error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string> cQrDatas;
        for (NSString *qrData in data) {
            cQrDatas.push_back([qrData UTF8String]);
        }
        Chain chainValue = Chain::MAIN;
        switch (chain) {
            case MAIN:
                chainValue = Chain::MAIN;
                break;
            case TESTNET:
                chainValue = Chain::TESTNET;
                break;
            case REGTEST:
                chainValue = Chain::REGTEST;
                break;
            case SIGNET:
                chainValue = Chain::SIGNET;
                break;
        }
        auto wallet = Utils::ParseKeystoneWallet(chainValue, cQrDatas);
        NSString *bsms = [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(wallet, ExportFormat::BSMS).c_str()];
        std::vector<std::string> addresses = Utils::DeriveAddresses(wallet, 0, 0);
        if (addresses.size() == 1) {
            auto firstAddress = addresses[0];
            NSString *address = [NSString stringWithUTF8String:firstAddress.c_str()];
            ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet:&wallet];
            return [[ObjWalletData alloc] initWithWallet:objWallet bsms:bsms firstAddress:address];
        } else {
            return NULL;
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWalletData *)getBSMSAndFirstAddress:(NSString *)config chain:(ChainTypeEnum)chain error:(NSError **)error {
    try {
        Chain chainValue = Chain::MAIN;
        switch (chain) {
            case MAIN:
                chainValue = Chain::MAIN;
                break;
            case TESTNET:
                chainValue = Chain::TESTNET;
                break;
            case REGTEST:
                chainValue = Chain::REGTEST;
                break;
            case SIGNET:
                chainValue = Chain::SIGNET;
                break;
        }
        auto wallet = Utils::ParseWalletConfig(chainValue, [config UTF8String]);
        NSString *bsms = [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(wallet, ExportFormat::BSMS).c_str()];
        std::vector<std::string> addresses = Utils::DeriveAddresses(wallet, 0, 0);
        if (addresses.size() == 1) {
            auto firstAddress = addresses[0];
            NSString *address = [NSString stringWithUTF8String:firstAddress.c_str()];
            ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet:&wallet];
            return [[ObjWalletData alloc] initWithWallet:objWallet bsms:bsms firstAddress:address];
        } else {
            return NULL;
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)parseJsonWalletData:(NSString *)json error:(NSError **)error {
    try {
        NSMutableArray *array = [NSMutableArray new];
        auto wallets = nunchukManager->nu->ParseJSONWallets([json UTF8String]);
        for (auto wallet: wallets) {
            ObjWallet *obj = [[ObjWallet alloc] initWithWallet:&wallet];
            NSString *bsms = [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(wallet, ExportFormat::BSMS).c_str()];
            std::vector<std::string> addresses = Utils::DeriveAddresses(wallet, 0, 0);
            if (addresses.size() == 1) {
                auto firstAddress = addresses[0];
                NSString *address = [NSString stringWithUTF8String:firstAddress.c_str()];
                [array addObject:[[ObjWalletData alloc] initWithWallet:obj bsms:bsms firstAddress:address]];
            }
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjWalletData *)getWalletData:(NSString *)walletId error:(NSError **)error {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        NSString *bsms = [NSString stringWithUTF8String:nunchukManager->nu->GetWalletExportData(wallet, ExportFormat::BSMS).c_str()];
        std::vector<std::string> addresses = Utils::DeriveAddresses(wallet, 0, 0);
        if (addresses.size() == 1) {
            auto firstAddress = addresses[0];
            NSString *address = [NSString stringWithUTF8String:firstAddress.c_str()];
            ObjWallet *objWallet = [[ObjWallet alloc] initWithWallet: &wallet];
            return [[ObjWalletData alloc] initWithWallet:objWallet bsms:bsms firstAddress:address];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)customizeTapsignerWithCVC:(NSString *)cvc masterSignerId:(NSString *)masterSignerId path:(NSString *)path error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        TapsignerStatus status = nunchukManager->nu->BackupTapsigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String]);
        NSString *cardId = [NSString stringWithUTF8String: status.get_card_ident().c_str()];
        std::vector<unsigned char> data = status.get_backup_data();
        SingleSigner signer = nunchukManager->nu->GetSignerFromTapsignerMasterSigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String], [path UTF8String]);
        [self invalidateSessionWithError:NULL];
        return @{@"data": [[NSData alloc] initWithBytes:data.data() length:sizeof(unsigned char) * data.size()], @"filename": [NSString stringWithFormat: @"backup.%.0f.%@.aes", [[NSDate date] timeIntervalSince1970], cardId], @"key": [[ObjSingleSigner alloc] initWithSigner:&signer]};
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)getSignerFromTapsignerMasterSigner:(NSString *)masterSignerId cvc:(NSString *)cvc addressType:(NSString *)addressType walletType:(NSString *)walletType error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        TapsignerStatus status = nunchukManager->nu->BackupTapsigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String]);
        std::vector<unsigned char> data = status.get_backup_data();
        AddressType cAddressType = [self addressTypeFromString:addressType];
        WalletType cWalletType = [self walletTypeFromString:walletType];
        SingleSigner signer = nunchukManager->nu->GetSignerFromTapsignerMasterSigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String], cWalletType, cAddressType, 0);
        [self invalidateSessionWithError:NULL];
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

// Rollover

- (NSNumber *)estimateRollOverTransactionCount:(NSString *)walletId tags:(NSArray *)tags collections:(NSArray *)collections error:(NSError **)error {
    try {
        std::set<int> cTags;
        for (NSNumber *tag in tags) {
            cTags.insert([tag intValue]);
        }
        std::set<int> cCollections;
        for (NSNumber *collection in collections) {
            cCollections.insert([collection intValue]);
        }
        return [NSNumber numberWithInt:nunchukManager->nu->EstimateRollOverTransactionCount([walletId UTF8String], cTags, cCollections)];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)estimateRollOverAmount:(NSString *)sourceWalletId destinationWalletId:(NSString *)destinationWalletId tags:(NSArray *)tags collections:(NSArray *)collections feeRate:(long)feeRate useScriptPath:(BOOL)useScriptPath error:(NSError **)error {
    try {
        std::set<int> cTags;
        for (NSNumber *tag in tags) {
            cTags.insert([tag intValue]);
        }
        std::set<int> cCollections;
        for (NSNumber *collection in collections) {
            cCollections.insert([collection intValue]);
        }
        auto value = nunchukManager->nu->EstimateRollOverAmount([sourceWalletId UTF8String], [destinationWalletId UTF8String], cTags, cCollections, feeRate, useScriptPath);
        return @{@"subamount": [NSNumber numberWithInt:value.first], @"fee": [NSNumber numberWithInt:value.second]};
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)draftRollOverTransactions:(NSString *)sourceWalletId destinationWalletId:(NSString *)destinationWalletId tags:(NSArray *)tags collections:(NSArray *)collections feeRate:(long)feeRate useScriptPath:(BOOL)useScriptPath error:(NSError **)error {
    try {
        std::set<int> cTags;
        for (NSNumber *tag in tags) {
            cTags.insert([tag intValue]);
        }
        std::set<int> cCollections;
        for (NSNumber *collection in collections) {
            cCollections.insert([collection intValue]);
        }
        NSMutableArray *temp = [NSMutableArray new];
        auto txs = nunchukManager->nu->DraftRollOverTransactions([sourceWalletId UTF8String], [destinationWalletId UTF8String], cTags, cCollections, feeRate, useScriptPath);
        for (auto&& tx: txs) {
            std::set<int> ctags = tx.first.first;
            NSMutableArray *tags = [NSMutableArray new];
            for(auto tagId: ctags) {
                [tags addObject:[NSNumber numberWithInt:tagId]];
            }
            std::set<int> cCollections = tx.first.second;
            NSMutableArray *collections = [NSMutableArray new];
            for(auto collectionId: cCollections) {
                [collections addObject:[NSNumber numberWithInt:collectionId]];
            }
            Transaction cTx = tx.second;
            ObjDraftRolloverTransaction *transaction = [[ObjDraftRolloverTransaction alloc] initWithTransaction:[[ObjTransaction alloc] initWithTransaction: &cTx] tagIds:tags collectionIds:collections];
            [temp addObject:transaction];
        }
        return temp;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)createRollOverTransactions:(NSString *)sourceWalletId destinationWalletId:(NSString *)destinationWalletId tags:(NSArray *)tags collections:(NSArray *)collections feeRate:(long)feeRate antiFeeSniping:(BOOL)antiFeeSniping useScriptPath:(BOOL)useScriptPath error:(NSError **)error {
    try {
        std::set<int> cTags;
        for (NSNumber *tag in tags) {
            cTags.insert([tag intValue]);
        }
        std::set<int> cCollections;
        for (NSNumber *collection in collections) {
            cCollections.insert([collection intValue]);
        }
        NSMutableArray *temp = [NSMutableArray new];
        auto txs = nunchukManager->nu->CreateRollOverTransactions([sourceWalletId UTF8String], [destinationWalletId UTF8String], cTags, cCollections, feeRate, antiFeeSniping, useScriptPath);
        for (auto& tx : txs) {
            ObjTransaction *obj = [[ObjTransaction alloc] initWithTransaction: &tx];
            [temp addObject:obj];
        }
        return temp;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)createPortalKeyWithName:(NSString *)name signer:(ObjSingleSigner *)signer error:(NSError * _Nullable __autoreleasing *)outError {
    try {
        std::vector<SignerTag> signertags;
        for (NSString *tag in signer.tags) {
            signertags.push_back(SignerTagFromStr([tag UTF8String]));
        }
        SingleSigner nsigner = nunchukManager->nu->CreateSigner([name UTF8String], [signer.xpub UTF8String], [signer.publicKey UTF8String], [signer.bip32Path UTF8String], [signer.masterFingerPrint UTF8String], SignerType::PORTAL_NFC, signertags, true);
        return [[ObjSingleSigner alloc] initWithSigner:&nsigner];
    } catch (const BaseException& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *outError = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSNumber *)getAddressIndex:(NSString *)walletId appDisplayAddress:(NSString *)appDisplayAddress error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto index = nunchukManager->nu->GetAddressIndex([walletId UTF8String], [appDisplayAddress UTF8String]);
        return [NSNumber numberWithInt:index];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getKeysetStatus:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto transaction = nunchukManager->nu->GetTransaction([walletId UTF8String], [txId UTF8String]);
        auto keySet = transaction.get_keyset_status();
        NSMutableArray *array = [NSMutableArray new];
        for (auto set : keySet) {
            ObjKeySetStatus *obj = [[ObjKeySetStatus alloc] initKeySetStatus:&set];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)enableGroupWallet:(NSString *)osName
                osVersion:(NSString *)osVersion
               appVersion:(NSString *)appVersion
                 deviceId:(NSString *)deviceId
              deviceClass:(NSString *)deviceClass
                 apiToken:(NSString *)apiToken
                    error:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->EnableGroupWallet([osName UTF8String], [osVersion UTF8String], [appVersion UTF8String], [deviceClass UTF8String], [deviceId UTF8String], [apiToken UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)startConsumeGroupEvent:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->StartConsumeGroupEvent();
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)stopConsumeGroupEvent:(NSError * _Nullable __autoreleasing *)error {
    try {
        nunchukManager->nu->StopConsumeGroupEvent();
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)sendGroupMessage:(NSString *)walletId
                 message:(NSString *)message
                  signer:(ObjSingleSigner *)signer
                   error:(NSError * _Nullable __autoreleasing *)error {
    try {
        if (signer) {
            std::pair<int, int> externalInternalIndex(0, 1);
            if (signer.externalInternalIndex != nil) {
                externalInternalIndex.first = signer.externalInternalIndex.first;
                externalInternalIndex.second = signer.externalInternalIndex.second;
            }
            SingleSigner singleSigner = SingleSigner([signer.signerName UTF8String], [signer.xpub UTF8String], [signer.publicKey UTF8String], [signer.bip32Path UTF8String], externalInternalIndex, [signer.masterFingerPrint UTF8String], signer.lastHealthCheckTS);
            singleSigner.set_type([self parseObjCSignerType:signer.type]);
            nunchukManager->nu->SendGroupMessage([walletId UTF8String], [message UTF8String], singleSigner);
        } else {
            nunchukManager->nu->SendGroupMessage([walletId UTF8String], [message UTF8String]);
        }
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getGroupMessages:(NSString *)walletId
                         page:(int)page
                     pageSize:(int)pageSize
                     isLatest:(BOOL)isLatest
                        error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto messages = nunchukManager->nu->GetGroupMessages([walletId UTF8String], page, pageSize, isLatest);
        NSMutableArray *array = [NSMutableArray new];
        for (auto message: messages) {
            ObjGroupMessage *obj = [[ObjGroupMessage alloc] initWithGroupMessage:&message];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjGroupConfig *)getGroupConfig:(NSError **)error {
    try {
        auto config = nunchukManager->nu->GetGroupConfig();
        return [[ObjGroupConfig alloc] initWithGroupConfig:&config];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" 
                                          code:exception.code() 
                                      userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" 
                                          code:NunchukSDKErrorUndefined 
                                      userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (void)observeGroupMessage {
    nunchukManager->nu->AddGroupMessageListener([self](GroupMessage message) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveGroupMessage:)]) {
            ObjGroupMessage *obj = [[ObjGroupMessage alloc] initWithGroupMessage:&message];
            [self.delegate didReceiveGroupMessage:obj];
        }
    });
}

- (ObjGroupWalletConfig *)getGroupWalletConfig:(NSString *)walletId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto config = nunchukManager->nu->GetGroupWalletConfig([walletId UTF8String]);
        return [[ObjGroupWalletConfig alloc] initWithGroupWalletConfig:&config];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)setGroupWalletConfig:(NSString *)walletId config:(ObjGroupWalletConfig *)config error:(NSError * _Nullable __autoreleasing *)error {
    try {
        GroupWalletConfig setting = nunchukManager->nu->GetGroupWalletConfig([walletId UTF8String]);
        setting.set_chat_retention_days(config.chatRetentionDays);
        nunchukManager->nu->SetGroupWalletConfig([walletId UTF8String], setting);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)createGroup:(NSString *)name m:(int)m n:(int)n addressType:(NSString *)addressType error:(NSError **)error {
    try {
        AddressType addrType = [self addressTypeFromString:addressType];
        auto group = nunchukManager->nu->CreateGroup([name UTF8String], m, n, addrType);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)getGroup:(NSString *)groupId error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->GetGroup([groupId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSNumber *)getGroupOnline:(NSString *)groupId error:(NSError **)error {
    try {
        int online = nunchukManager->nu->GetGroupOnline([groupId UTF8String]);
        return @(online);
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSArray<ObjGroupSandbox *> *)getGroups:(NSError **)error {
    try {
        auto groups = nunchukManager->nu->GetGroups();
        NSMutableArray<ObjGroupSandbox *> *array = [[NSMutableArray alloc] initWithCapacity:groups.size()];
        for (auto group: groups) {
            ObjGroupSandbox * objGroup = [[ObjGroupSandbox alloc] initWithGroupSandbox: &group];
            [array addObject: objGroup];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSDictionary<NSString*, NSString*> *)parseGroupUrl:(NSString *)url error:(NSError **)error {
    try {
        auto result = nunchukManager->nu->ParseGroupUrl([url UTF8String]);
        return @{
            @"groupId": [NSString stringWithUTF8String:result.first.c_str()],
            @"invitationCode": [NSString stringWithUTF8String:result.second.c_str()]
        };
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)joinGroup:(NSString *)groupId error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->JoinGroup([groupId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)addSignerToGroup:(NSString *)groupId signer:(ObjSingleSigner *)signer index:(int)index error:(NSError **)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (signer.externalInternalIndex != nil) {
            externalInternalIndex.first = signer.externalInternalIndex.first;
            externalInternalIndex.second = signer.externalInternalIndex.second;
        }
        auto cppSigner = SingleSigner(std::string([signer.signerName UTF8String]), std::string([signer.xpub UTF8String]), std::string([signer.publicKey UTF8String]), std::string([signer.bip32Path UTF8String]), externalInternalIndex, std::string([signer.masterFingerPrint UTF8String]), false);
        auto group = nunchukManager->nu->AddSignerToGroup([groupId UTF8String], cppSigner, index);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)addSignerToGroup:(NSString *)groupId signer:(ObjSingleSigner *)signer keyId:(NSString *)keyId error:(NSError **)error {
    try {
        std::pair<int, int> externalInternalIndex(0, 1);
        if (signer.externalInternalIndex != nil) {
            externalInternalIndex.first = signer.externalInternalIndex.first;
            externalInternalIndex.second = signer.externalInternalIndex.second;
        }
        auto cppSigner = SingleSigner(std::string([signer.signerName UTF8String]), std::string([signer.xpub UTF8String]), std::string([signer.publicKey UTF8String]), std::string([signer.bip32Path UTF8String]), externalInternalIndex, std::string([signer.masterFingerPrint UTF8String]), false);
        auto group = nunchukManager->nu->AddSignerToGroup([groupId UTF8String], cppSigner, [keyId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)removeSignerFromGroup:(NSString *)groupId index:(int)index error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->RemoveSignerFromGroup([groupId UTF8String], index);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)removeSignerFromGroup:(NSString *)groupId keyId:(NSString *)keyId error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->RemoveSignerFromGroup([groupId UTF8String], [keyId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)updateGroup:(NSString *)groupId name:(NSString *)name m:(int)m n:(int)n scriptTmpl:(NSString *)scriptTmpl addressType:(NSString *)addressType error:(NSError **)error {
    try {
        AddressType addrType = [self addressTypeFromString:addressType];
        // Check if scriptTmpl is null or empty to determine which UpdateGroup function to call
        if (scriptTmpl == nil || [scriptTmpl length] == 0) {
            // Call UpdateGroup for multisig wallet
            auto group = nunchukManager->nu->UpdateGroup([groupId UTF8String], [name UTF8String], m, n, addrType);
            return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
        } else {
            // Call UpdateGroup for miniscript wallet
            auto group = nunchukManager->nu->UpdateGroup([groupId UTF8String], [name UTF8String], [scriptTmpl UTF8String], addrType);
            return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
        }
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)finalizeGroup:(NSString *)groupId valueKeyset:(NSArray *)valueKeyset error:(NSError **)error {
    try {
        std::set<size_t> set;
        for (NSNumber *value in valueKeyset) {
            set.insert([value intValue]);
        }
        auto group = nunchukManager->nu->FinalizeGroup([groupId UTF8String], set);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        if (exception.code() == GroupException::SANDBOX_FINALIZED) {
            *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorGroupSandboxFinalized userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
            return NULL;
        }
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (BOOL)deleteGroup:(NSString *)groupId error:(NSError *_Nullable*_Nullable)error {
    try {
        nunchukManager->nu->DeleteGroup([groupId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (void)observeGroupSandbox {
    nunchukManager->nu->AddGroupUpdateListener([self](GroupSandbox groupSanbox) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateGroupSanbox:)]) {
            ObjGroupSandbox *obj = [[ObjGroupSandbox alloc] initWithGroupSandbox:&groupSanbox];
            [self.delegate didUpdateGroupSanbox:obj];
        }
    });
}

- (void)observeGroupOnline {
    nunchukManager->nu->AddGroupOnlineListener([self](std::string groupId, int online) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateGroupOnline:online:)]) {
            [self.delegate didUpdateGroupOnline:[NSString stringWithUTF8String:groupId.c_str()] online:online];
        }
    });
}

- (void)observeGroupDeleted {
    nunchukManager->nu->AddGroupDeleteListener([self](std::string groupId) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didDeletedGroupSandbox:)]) {
            [self.delegate didDeletedGroupSandbox:[NSString stringWithUTF8String:groupId.c_str()]];
        }
    });
}

- (ObjGroupSandbox *)setSlotOccupied:(NSString *)groupId index:(int)index value:(BOOL)value error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->SetSlotOccupied([groupId UTF8String], index, value);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)setSlotOccupied:(NSString *)groupId keyId:(NSString *)keyId value:(BOOL)value error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->SetSlotOccupied([groupId UTF8String], [keyId UTF8String], value);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSString *)getGroupDeviceUID:(NSError **)error {
    try {
        auto deviceUID = nunchukManager->nu->GetGroupDeviceUID();
        return [NSString stringWithUTF8String:deviceUID.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSArray *)getGroupWallets:(NSError **)error {
    try {
        NSMutableArray *array = [NSMutableArray new];
        auto wallets = nunchukManager->nu->GetGroupWallets();
        for (auto wallet: wallets) {
            ObjWallet *obj = [[ObjWallet alloc] initWithWallet:&wallet];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
    }
}

- (NSArray<NSString *> *)getDeprecatedGroupWallets:(NSError **)error {
    try {
        auto walletIds = nunchukManager->nu->GetDeprecatedGroupWallets();
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (auto&& walletId : walletIds) {
            [result addObject:[NSString stringWithUTF8String:walletId.c_str()]];
        }
        return result;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (int)getUnreadMessagesCount:(NSString *)walletId {
    try {
        return nunchukManager->nu->GetUnreadMessagesCount([walletId UTF8String]);
    } catch (const BaseException& exception) {
        return 0;
    } catch (const std::exception& exception) {
        return 0;
    }
}

- (BOOL)setLastReadMessage:(NSString *)walletId messageId:(NSString *)messageId error:(NSError **)error {
    try {
        nunchukManager->nu->SetLastReadMessage([walletId UTF8String], [messageId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjWallet *)isGroupWalletExisted:(NSString *)content error:(NSError **)error {
    try {
        auto wallet = Utils::ParseWalletDescriptor([content UTF8String]);
        BOOL isGroupWallet = nunchukManager->nu->CheckGroupWalletExists(wallet);
        if (isGroupWallet) {
            return [[ObjWallet alloc] initWithWallet: &wallet];
        }
        return NULL;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)recoverGroupWallet:(NSString *)walletId error:(NSError **)error {
    try {
        nunchukManager->nu->RecoverGroupWallet([walletId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NO;
    }
}

- (ObjGroupSandbox *)createReplaceGroup:(NSString *)walletId error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->CreateReplaceGroup([walletId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSString *)decryptGroupWalletId:(NSString *)walletId error:(NSError **)error {
    try {
        return [NSString stringWithUTF8String: nunchukManager->nu->DecryptGroupWalletId([walletId UTF8String]).c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjGroupSandbox *)acceptReplaceGroup:(NSString *)walletId groupId:(NSString *)groupId error:(NSError **)error {
    try {
        auto group = nunchukManager->nu->AcceptReplaceGroup([walletId UTF8String], [groupId UTF8String]);
        return [[ObjGroupSandbox alloc] initWithGroupSandbox:&group];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

- (NSString *)decryptGroupTxId:(NSString *)txId walletId:(NSString *)walletId error:(NSError **)error {
    try {
        return [NSString stringWithUTF8String: nunchukManager->nu->DecryptGroupTxId([walletId UTF8String], [txId UTF8String]).c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)declineReplaceGroup:(NSString *)walletId groupId:(NSString *)groupId error:(NSError **)error {
    try {
        nunchukManager->nu->DeclineReplaceGroup([walletId UTF8String], [groupId UTF8String]);
        return YES;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NO;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NO;
    }
}

- (NSDictionary<NSString*, NSNumber*> *)getReplaceGroups:(NSString *)walletId error:(NSError **)error {
    try {
        auto replacements = nunchukManager->nu->GetReplaceGroups([walletId UTF8String]);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (const auto& [groupId, accepted] : replacements) {
            [dict setObject:@(accepted) forKey:[NSString stringWithUTF8String:groupId.c_str()]];
        }
        return dict;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:exception.code() userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String:exception.what()]}];
        return NULL;
    }
}

// Add observer implementation
- (void)observeReplaceRequest {
    nunchukManager->nu->AddReplaceRequestListener([self](std::string walletId, std::string replaceGroupId) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveReplaceRequest:replaceGroupId:)]) {
            [self.delegate didReceiveReplaceRequest:[NSString stringWithUTF8String:walletId.c_str()] 
                                   replaceGroupId:[NSString stringWithUTF8String:replaceGroupId.c_str()]];
        }
    });
}

- (BOOL)exportTransactionHistoryWithWalletId:(NSString *)walletId filePath:(NSString *)filePath format:(NunchukExportFormat)format error:(NSError **)error {
    try {
        auto exportFormat = [self parseExportFormat:format];
        return nunchukManager->nu->ExportTransactionHistory([walletId UTF8String], [filePath UTF8String], exportFormat);
    } catch (const std::exception &e) {
        NSLog(@"[NunchukImp] exportTransactionHistoryWithWalletId exception: %s", e.what());
        if (error) {
            *error = [NSError errorWithDomain:@"NunchukImp" code:NunchukSDKErrorUndefined userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", e.what()]}];
        }
        return NO;
    }
}

- (NSNumber *)getScriptPathFeeRateWithWalletId:(NSString *)walletId transaction:(ObjTransaction *)transaction error:(NSError **)error {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        UInt64 subAmount = transaction.subAmount;
        UInt64 fee = transaction.fee;
        UInt64 feeRate = transaction.feeRate;
        Transaction tx = Utils::DecodeTx(wallet, [transaction.psbt UTF8String], subAmount, fee, feeRate);
        Amount scriptPathFeeRate = nunchukManager->nu->GetScriptPathFeeRate([walletId UTF8String], tx);
        return [NSNumber numberWithLongLong:scriptPathFeeRate];
    } catch (const std::exception &e) {
        NSLog(@"[NunchukImp] getScriptPathFeeRateWithWalletId exception: %s", e.what());
        if (error) {
            *error = [NSError errorWithDomain:@"NunchukImp" code:NunchukSDKErrorUndefined userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", e.what()]}];
        }
        return nil;
    }
}

- (NSArray<ObjSingleSigner *> *)getMultipleSignersFromTapsignerMasterSigner:(NSString *)masterSignerId 
                                                                       cvc:(NSString *)cvc 
                                                                walletType:(NSString *)walletType 
                                                               addressType:(NSString *)addressType 
                                                                   indices:(NSArray<NSNumber *> *)indices 
                                                                     error:(NSError **)error {
    try {
        std::unique_ptr<Tapsigner> card = [self createTapsignerWithError:error];
        if (*error != NULL) {
            if ((*error).code == TapProtocolException::RATE_LIMIT) {
                if (![self waitTapsigner:card.get() error:error]) {
                    [self invalidateSessionWithError:*error];
                    return NULL;
                }
            } else {
                [self invalidateSessionWithError:*error];
                return NULL;
            }
        }
        TapsignerStatus status = nunchukManager->nu->BackupTapsigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String]);
        AddressType cAddressType = [self addressTypeFromString:addressType];
        WalletType cWalletType = [self walletTypeFromString:walletType];
        NSMutableArray<ObjSingleSigner *> *signers = [NSMutableArray array];
        for (NSNumber *indexNumber in indices) {
            int index = [indexNumber intValue];
            auto singleSigner = nunchukManager->nu->GetSignerFromTapsignerMasterSigner(card.get(), [cvc UTF8String], [masterSignerId UTF8String], cWalletType, cAddressType, index);
            [signers addObject:[[ObjSingleSigner alloc] initWithSigner:&singleSigner]];
        }
        
        [self invalidateSessionWithError:NULL];
        return [signers copy];
    } catch (const BaseException& exception) {
        *error = [self handleNFCException:exception];
        return NULL;
    } catch (const std::exception& exception) {
        [self invalidateSessionWithError:*error];
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<ObjSigningPathFee *> *)estimateFeeForSigningPaths:(NSString *)walletId outputs:(NSArray<StringIntPair *> *)outputs inputs:(NSArray<ObjUnspentOutput *> *)input feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError * _Nullable __autoreleasing *)error {
    std::map<std::string, Amount> cOutputs;
    std::vector<UnspentOutput> inputs;
    for(NSUInteger i = 0; i < outputs.count; i++) {
        StringIntPair * pair = outputs[i];
        cOutputs[[pair.key UTF8String]] = pair.value;
    }
    
    for(NSUInteger i = 0; i < input.count; i++) {
        UnspentOutput cInput = [input[i] convertToC];
        inputs.push_back(cInput);
    }
    try {
        auto signingPaths = nunchukManager->nu->EstimateFeeForSigningPaths([walletId UTF8String], cOutputs, inputs, feeRate, subtractFeeFromAmount);
        NSMutableArray *temp = [NSMutableArray new];
        for (auto& item: signingPaths) {
            SigningPath path = item.first;
            NSMutableArray *scriptNodeIdArray = [NSMutableArray arrayWithCapacity:path.size()];
            for (ScriptNodeId scriptNodeId: path) {
                NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:scriptNodeId.size()];
                for (size_t idValue: scriptNodeId) {
                    [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
                }
                [scriptNodeIdArray addObject:idArray];
            }
            ObjSigningPath *signingPathObj = [[ObjSigningPath alloc] initWithScriptNodeIds:scriptNodeIdArray];
            ObjSigningPathFee *obj = [[ObjSigningPathFee alloc] initWithSigningPath:signingPathObj amount:item.second];
            [temp addObject:obj];
        }
        return temp;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSDictionary *)getTimelockedUntilWithWalletId:(NSString *)walletId transactionId:(NSString *)transactionId {
    try {
        auto timelocked = nunchukManager->nu->GetTimelockedUntil([walletId UTF8String], [transactionId UTF8String]);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        if (timelocked.first != UNDETERMINED_TIMELOCK_VALUE) {
            [dict setObject:[NSNumber numberWithLongLong:timelocked.first] forKey:@"value"];
        }
        TimeLockBased based = [self getTimeLockBased:timelocked.second];
        [dict setObject:[NSNumber numberWithInt:based] forKey:@"based"];
        return dict;
    } catch (const BaseException& exception) {
        return NULL;
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

- (NSDictionary *_Nullable)getCoinsGroupedBySubPolicies:(NSString *_Nonnull)script coins:(NSArray *_Nonnull)coins {
    try {
        std::vector<std::string> keypaths;
        auto scriptNode = Utils::GetScriptNode([script UTF8String], keypaths);
        return [self getCoinsGroupedBySubPoliciesWithNode:scriptNode coins:coins];
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (NSDictionary *)getCoinsGroupedBySubPoliciesWithNode:(const ScriptNode &)node coins:(NSArray *_Nonnull)coins {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    std::vector<UnspentOutput> coinsC;
    try {
        ScriptNode::Type type = node.get_type();
        if (type == ScriptNode::Type::ANDOR
            || type == ScriptNode::Type::OR
            || type == ScriptNode::Type::THRESH
            || type == ScriptNode::Type::OR_TAPROOT) {
            for (ObjUnspentOutput *coin in coins) {
                coinsC.push_back([coin convertToC]);
            }
            auto groups = Utils::GetCoinsGroupedBySubPolicies(node, coinsC, nunchukManager->nu->GetChainTip());
            if (groups.size() > 0) {
                NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:groups.size()];
                for (auto &group : groups) {
                    ObjCoinGroup *obj = [[ObjCoinGroup alloc] initWithCoinGroup:group];
                    [array addObject:obj];
                }
                const std::vector<size_t>& nodeId = node.get_id();
                NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:nodeId.size()];
                for (size_t idValue : nodeId) {
                    [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
                }
                NSString *nodeIdStr = [idArray componentsJoinedByString:@"."];
                [dict setObject:array forKey:nodeIdStr];
            }
        }
        const std::vector<ScriptNode>& subs = node.get_subs();
        for (const ScriptNode& subNode : subs) {
            NSDictionary *subDict = [self getCoinsGroupedBySubPoliciesWithNode:subNode coins:coins];
            [dict addEntriesFromDictionary:subDict];
        }
        return dict;
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (BOOL)isPreferScriptPath:(NSString *)walletId txId:(NSString *)txId {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        return nunchukManager->nu->IsPreferScriptPath(wallet, [txId UTF8String]);
    } catch (const BaseException& exception) {
        return YES;
    }
}

- (void)setPreferScriptPath:(NSString *)walletId txId:(NSString *)txId preferScriptPath:(BOOL)preferScriptPath {
    try {
        auto wallet = nunchukManager->nu->GetWallet([walletId UTF8String]);
        nunchukManager->nu->SetPreferScriptPath(wallet, [txId UTF8String], preferScriptPath);
    } catch (const BaseException& exception) {
        return;
    }
}

- (NSDictionary *_Nullable)getScriptNodeKeySetStatus:(NSString *_Nonnull)script walletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId {
    try {
        Transaction tx = nunchukManager->nu->GetTransaction([walletId UTF8String], [txId UTF8String]);
        std::vector<std::string> keypaths;
        auto scriptNode = Utils::GetScriptNode([script UTF8String], keypaths);
        return [self getNodeKeySetStatus:scriptNode tx:tx];
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (NSDictionary *)getNodeKeySetStatus:(const ScriptNode &)node tx:(Transaction)tx {
    try {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        ScriptNode::Type type = node.get_type();
        if (type == ScriptNode::Type::MUSIG) {
            auto keySetStatus = node.get_keyset_status(tx);
            const std::vector<size_t>& nodeId = node.get_id();
            NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:nodeId.size()];
            for (size_t idValue : nodeId) {
                [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
            }
            NSString *nodeIdStr = [idArray componentsJoinedByString:@"."];
            ObjKeySetStatus *obj = [[ObjKeySetStatus alloc] initKeySetStatus: &keySetStatus];
            [dict setObject:obj forKey:nodeIdStr];
        }
        const std::vector<ScriptNode>& subs = node.get_subs();
        for (const ScriptNode& subNode : subs) {
            NSDictionary *subDict = [self getNodeKeySetStatus:subNode tx:tx];
            if (subDict != NULL) {
                [dict addEntriesFromDictionary:subDict];
            }
        }
        return dict;
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (NSArray<ObjUnspentOutput *> *)getTimelockedCoins:(NSString *)script walletId:(NSString *_Nonnull)walletId {
    try {
        auto coins = nunchukManager->nu->GetUnspentOutputs([walletId UTF8String]);
        int64_t maxLockValue;
        auto unlockedCoins = Utils::GetTimelockedCoins([script UTF8String], coins, maxLockValue, nunchukManager->nu->GetChainTip());
        NSMutableArray *array = [NSMutableArray array];
        for (auto &coin : unlockedCoins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
            [array addObject:obj];
        }
        return array;
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (NSDictionary *)getTimelockedCoinsFromCoins:(NSArray<ObjUnspentOutput *> *)coins script:(NSString *)script {
    try {
        std::vector<UnspentOutput> coinInputs;
        for (ObjUnspentOutput *input in coins) {
            UnspentOutput cInput = [input convertToC];
            coinInputs.push_back(cInput);
        }
        int64_t maxLockValue;
        auto timelockedCoins = Utils::GetTimelockedCoins([script UTF8String], coinInputs, maxLockValue, nunchukManager->nu->GetChainTip());
        NSMutableArray *array = [NSMutableArray array];
        for (auto &coin : timelockedCoins) {
            ObjUnspentOutput *obj = [[ObjUnspentOutput alloc] initWithUnspentOutput:&coin];
            [array addObject:obj];
        }
        return @{ @"coins": array, @"max_value": [NSNumber numberWithLongLong:maxLockValue] };
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (BOOL)revealPreimage:(NSString *)walletId txId:(NSString *)txId hash:(NSData *)hash preImage:(NSString *)preImage {
    try {
        const uint8_t *hashBytes = (const uint8_t *)[hash bytes];
        NSUInteger dataLength = [hash length];
        std::vector<uint8_t> hashC(hashBytes, hashBytes + dataLength);
        std::vector<uint8_t> preimageC;
        std::string preImageArray = [preImage UTF8String];
        if (preImageArray.length() % 2 != 0) {
            return FALSE;
        }
        for (size_t i = 0; i < preImageArray.length(); i += 2) {
            std::string byteString = preImageArray.substr(i, 2);
            unsigned long byteValue = std::strtoul(byteString.c_str(), nullptr, 16);
            preimageC.push_back(static_cast<uint8_t>(byteValue));
        }
        return nunchukManager->nu->RevealPreimage([walletId UTF8String], [txId UTF8String], hashC, preimageC);
    } catch (const BaseException& exception) {
        return FALSE;
    }
}

- (NSArray<ObjSigningPathFee *> *)estimateFeeForRBFSigningPaths:(NSString *)walletId txId:(NSString *)txId newAddress:(NSString *)newAddress feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto tx = nunchukManager->nu->GetTransaction([walletId UTF8String], [txId UTF8String]);
        if (tx.get_status() == TransactionStatus::CONFIRMED) {
            throw BaseException(NunchukSDKErrorInvalidTxStatus, "Cannot replace transaction. The original transaction has already been confirmed");
        }
        auto inputs = nunchukManager->nu->GetUnspentOutputsFromTxInputs([walletId UTF8String], tx.get_inputs());
        auto totalAmount = 0;
        for (auto input : inputs) {
            totalAmount += input.get_amount();
        }
        std::map<std::string, Amount> outputs;
        outputs[[newAddress UTF8String]] = totalAmount;
        auto signingPaths = nunchukManager->nu->EstimateFeeForSigningPaths([walletId UTF8String], outputs, inputs, feeRate, subtractFeeFromAmount);
        NSMutableArray *temp = [NSMutableArray new];
        for (auto& item: signingPaths) {
            SigningPath path = item.first;
            NSMutableArray *scriptNodeIdArray = [NSMutableArray arrayWithCapacity:path.size()];
            for (ScriptNodeId scriptNodeId: path) {
                NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:scriptNodeId.size()];
                for (size_t idValue: scriptNodeId) {
                    [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
                }
                [scriptNodeIdArray addObject:idArray];
            }
            ObjSigningPath *signingPathObj = [[ObjSigningPath alloc] initWithScriptNodeIds:scriptNodeIdArray];
            ObjSigningPathFee *obj = [[ObjSigningPathFee alloc] initWithSigningPath:signingPathObj amount:item.second];
            [temp addObject:obj];
        }
        return temp;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<ObjSingleSigner *> *)getTransactionSigners:(NSString *)walletId txId:(NSString *)txId error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto signers = nunchukManager->nu->GetTransactionSigners([walletId UTF8String], [txId UTF8String]);
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:signers.size()];
        for(unsigned i = 0; i < signers.size(); i++) {
            auto signer = signers.at(i);
            ObjSingleSigner * objSigner = [[ObjSingleSigner alloc] initWithSigner: &signer];
            [array addObject: objSigner];
        }
        return array;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

@end
