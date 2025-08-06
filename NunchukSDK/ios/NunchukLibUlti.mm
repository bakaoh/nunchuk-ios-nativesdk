//
//  NunchukLibUlti.m
//  nunchukSDK
//
//  Created by Thai Nguyen on 5/30/22.
//

#import <Foundation/Foundation.h>
#import "NunchukLibUlti.h"
#include <nunchuk.h>
#import "NunchukImp.h"
#import "ObjPrimaryKey.h"
#import <extensions/ObjPrimaryKey+Extension.h>
#import "ObjBtcUri.h"
#import <extensions/ObjBtcUri+Extension.h>
#include "utils/ndef.hpp"
#include "utils/coldcard.hpp"
#include "utils/rfc2440.hpp"
#import <extensions/ObjTransactionLibrary.h>
#import "extensions/ObjSingleSignerLibrary.h"
#import <extensions/ObjScriptNode+Extension.h>
#import <extensions/ObjTimeLock+Extension.h>
#import "ObjTimeLock.h"

using namespace nunchuk::ndef;
using namespace nunchuk;

@implementation NunchukLibUlti

- (instancetype)init {
  if (self = [super init]) {
  }
  return self;
}

+ (instancetype)shared {
    static NunchukLibUlti *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (NSString *)generateMnemonic {
    try {
        return [NSString stringWithUTF8String: Utils::GenerateMnemonic().c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)generateMnemonic12Words {
    try {
        return [NSString stringWithUTF8String: Utils::GenerateMnemonic12Words().c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)getPrimaryKeyAddressWithMnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase {
    try {
        return [NSString stringWithUTF8String: Utils::GetPrimaryKeyAddress([mnemonic UTF8String], [passphrase UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)getPrimaryKeyAddressWithXPRV:(NSString *)xprv {
    try {
        return [NSString stringWithUTF8String: Utils::GetPrimaryKeyAddressFromMasterXprv([xprv UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)signLoginMessageWithMnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase message:(NSString *)message {
    try {
        return [NSString stringWithUTF8String: Utils::SignLoginMessage([mnemonic UTF8String], [passphrase UTF8String], [message UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)signLoginMessageWithXPRV:(NSString *)xprv message:(NSString *)message {
    try {
        return [NSString stringWithUTF8String: Utils::SignLoginMessageWithMasterXprv([xprv UTF8String], [message UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (BOOL)isMnemonicValid:(NSString *)mnemonic {
    try {
        return Utils::CheckMnemonic([mnemonic UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSArray *)getBip39:(NSError **)error {
    try {
        std::vector<std::string> list = Utils::GetBIP39WordList();
        NSMutableArray * mArray = [[NSMutableArray alloc] init];
        for(auto& str : list) {
            [mArray addObject:[[NSString alloc] initWithUTF8String: str.c_str()]];
        }
        return mArray;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getMasterFingerprintWithMnemonic:(NSString *)mnemonic passphrase:(NSString *)passphrase {
    try {
        return [NSString stringWithUTF8String: Utils::GetMasterFingerprint([mnemonic UTF8String], [passphrase UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)getMasterFingerprintWithXPRV:(NSString *)xprv {
    try {
        return [NSString stringWithUTF8String: Utils::GetMasterFingerprintFromMasterXprv([xprv UTF8String]).c_str()];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSArray *)getPrimaryKeysWithStoragePath:(NSString *)storagePath chain:(ChainTypeEnum)chain {
    try {
        NSMutableArray *array = [[NSMutableArray alloc] init];
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
        std::vector<PrimaryKey> keys = Utils::GetPrimaryKeys([storagePath UTF8String], chainValue);
        for(auto& key: keys) {
            ObjPrimaryKey *primaryKey = [[ObjPrimaryKey alloc] initWithPrimaryKey:&key];
            [array addObject:primaryKey];
        }
        return array;
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (BOOL)setChain:(ChainTypeEnum)chain {
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
        Utils::SetChain(chainValue);
        return YES;
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (ChainTypeEnum)getChain {
    try {
        Chain chain = Utils::GetChain();
        ChainTypeEnum chainValue = MAIN;
        switch (chain) {
            case Chain::MAIN:
                chainValue = MAIN;
                break;
            case Chain::TESTNET:
                chainValue = TESTNET;
                break;
            case Chain::REGTEST:
                chainValue = REGTEST;
                break;
            case Chain::SIGNET:
                chainValue = SIGNET;
                break;
        }
        return chainValue;
    } catch (const std::exception& exception) {
        return MAIN;
    }
}

- (UInt64)amountFromValue:(NSString *_Nonnull)value {
    try {
        int64_t amount = Utils::AmountFromValue([value UTF8String]);
        return amount > 0 ? amount : 0;
    } catch (const std::exception& exception) {
        return 0;
    }
}

- (NSString *_Nonnull)valueFromAmount:(UInt64)amount {
    try {
        return [NSString stringWithUTF8String:Utils::ValueFromAmount(amount).c_str()];
    } catch (const std::exception& exception) {
        return @"";
    }
}

- (ObjBtcUri *)parseBtcUri:(NSString *)qr error:(NSError **)error {
    try {
        auto btcUri = Utils::ParseBtcUri([qr UTF8String]);
        return [[ObjBtcUri alloc] initWithBTCUri:btcUri];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NCNDEFMessageType)getNDEFType:(NSArray *)records {
    std::vector<NDEFRecord> ndefRecords;
    for (NFCNDEFPayload *record in records) {
        NDEFRecord ndefRecord = [self makeNDEFRecord:record];
        ndefRecords.push_back(ndefRecord);
    }
    auto type = nunchuk::ndef::DetectNDEFMessageType(ndefRecords);
    return [self ndefMessageTypeFrom:type];
}

- (NSString *)ndefRecordToJson:(NFCNDEFPayload *)record {
    auto ndefRecord = [self makeNDEFRecord:record];
    auto json = nunchuk::ndef::NDEFRecordToJSON(ndefRecord);
    return [NSString stringWithUTF8String:json.c_str()];
}

- (NSString *)ndefRecordToString:(NFCNDEFPayload *)record {
    auto ndefRecord = [self makeNDEFRecord:record];
    auto json = nunchuk::ndef::NDEFRecordToStr(ndefRecord);
    return [NSString stringWithUTF8String:json.c_str()];
}

- (NSString *)ndefRecordToPSBT:(NSArray *)records {
    std::vector<NDEFRecord> ndefRecords;
    for (NFCNDEFPayload *record in records) {
        NDEFRecord ndefRecord = [self makeNDEFRecord:record];
        ndefRecords.push_back(ndefRecord);
    }
    auto psbt = nunchuk::ndef::NDEFRecordsToPSBT(ndefRecords);
    return [NSString stringWithUTF8String:psbt.c_str()];
}

- (NSString *)ndefRecordToRawTransaction:(NSArray *)records {
    std::vector<NDEFRecord> ndefRecords;
    for (NFCNDEFPayload *record in records) {
        NDEFRecord ndefRecord = [self makeNDEFRecord:record];
        ndefRecords.push_back(ndefRecord);
    }
    auto rawData = nunchuk::ndef::NDEFRecordsToRawTransaction(ndefRecords);
    return [NSString stringWithUTF8String:rawData.c_str()];
}

- (NSArray *)ndefRecordFromString:(NSString *)data {
    NSMutableArray *array = [NSMutableArray new];
    auto records = nunchuk::ndef::NDEFRecordsFromStr([data UTF8String]);
    for (auto &record: records) {
        NFCNDEFPayload *obj = [self makeObjNDEFRecord:record];
        [array addObject:obj];
    }
    return array;
}

- (NSArray *)ndefRecordFromPSBT:(NSString *)data {
    NSMutableArray *array = [NSMutableArray new];
    auto records = nunchuk::ndef::NDEFRecordsFromPSBT([data UTF8String]);
    for (auto &record: records) {
        NFCNDEFPayload *obj = [self makeObjNDEFRecord:record];
        if (obj != nil) {
            [array addObject:obj];
        }
    }
    return array;
}

- (NCNDEFMessageType)ndefMessageTypeFrom:(NDEFMessageType)type {
    NCNDEFMessageType messageType;
    switch (type) {
        case NDEFMessageType::UNKNOWN:
            messageType = UNKNOWN;
            break;
        case NDEFMessageType::TAPSIGNER:
            messageType = TAPSIGNER;
            break;
        case NDEFMessageType::SATSCARD:
            messageType = SATSCARD;
            break;
        case NDEFMessageType::JSON:
            messageType = JSON;
            break;
        case NDEFMessageType::PSBT:
            messageType = PSBT;
            break;
        case NDEFMessageType::TRANSACTION:
            messageType = TRANSACTION;
            break;
        case NDEFMessageType::ADDRESS:
            messageType = ADDRESS;
            break;
        case NDEFMessageType::MULTIPLE_ADDRESSES:
            messageType = MULTIPLE_ADDRESSES;
            break;
        case NDEFMessageType::TEXT:
            messageType = TEXT;
            break;
        case NDEFMessageType::WALLET:
            messageType = WALLET;
            break;
        default:
            messageType = UNKNOWN;
            break;
    }
    return messageType;
}

- (NFCNDEFPayload *)makeObjNDEFRecord:(NDEFRecord)record {
    NSData *type = [[NSData alloc] initWithBytes:record.type.data() length:sizeof(unsigned char) * record.type.size()];
    NSData *recordId = [[NSData alloc] initWithBytes:record.id.data() length:sizeof(unsigned char) * record.id.size()];
    NSData *payload = [[NSData alloc] initWithBytes:record.payload.data() length:sizeof(unsigned char) * record.payload.size()];
    return [[NFCNDEFPayload alloc] initWithFormat:(NFCTypeNameFormat)record.typeNameFormat type:type identifier:recordId payload:payload];
}

- (NDEFRecord)makeNDEFRecord:(NFCNDEFPayload *)objRecord {
    const unsigned char *typeDataArray = (unsigned char *)objRecord.type.bytes;
    const size_t typeCount = objRecord.type.length / sizeof(unsigned char);
    std::vector<unsigned char> typeData(typeDataArray, typeDataArray + typeCount);
    
    const unsigned char *idDataArray = (unsigned char *)objRecord.identifier.bytes;
    const size_t idCount = objRecord.identifier.length / sizeof(unsigned char);
    std::vector<unsigned char> idData(idDataArray, idDataArray + idCount);
    
    const unsigned char *payloadDataArray = (unsigned char *)objRecord.payload.bytes;
    const size_t payloadCount = objRecord.payload.length / sizeof(unsigned char);
    std::vector<unsigned char> payloadData(payloadDataArray, payloadDataArray + payloadCount);
    
    return NDEFRecord(objRecord.typeNameFormat, typeData, idData, payloadData);
}

- (NSArray *)generateColdCardHealthCheckNDEFMessage:(NSString *)path {
    try {
        std::string message = GenerateColdCardHealthCheckMessage([path UTF8String]);
        return [self ndefRecordFromString:[NSString stringWithUTF8String:message.c_str()]];
    } catch (const std::exception& exception) {
        return NULL;
    }
}

- (NSString *)createRequestTokenWithSignature:(NSString *)signature fingerprint:(NSString *)fingerprint {
    return [NSString stringWithUTF8String: Utils::CreateRequestToken([signature UTF8String], [fingerprint UTF8String]).c_str()];
}

- (NSString *)getHealthCheckMessageWithBody:(NSString *)body {
    return [NSString stringWithUTF8String: Utils::GetHealthCheckMessage([body UTF8String]).c_str()];
}

- (NSArray<NSString *> *)exportKeystoneTransactionWithPsbt:(NSString *)psbt fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string> qrs = Utils::ExportKeystoneTransaction([psbt UTF8String], fragmentLength);
        NSMutableArray *qrDatas = [[NSMutableArray alloc] init];
        for(auto& qr : qrs) {
            [qrDatas addObject:[[NSString alloc] initWithUTF8String: qr.c_str()]];
        }
        return qrDatas;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray<NSString *> *)exportBBQRTransactionWithPsbt:(NSString *)psbt fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string> qrs = Utils::ExportBBQRTransaction([psbt UTF8String], 1, fragmentLength);
        NSMutableArray *qrDatas = [[NSMutableArray alloc] init];
        for(auto& qr : qrs) {
            [qrDatas addObject:[[NSString alloc] initWithUTF8String: qr.c_str()]];
        }
        return qrDatas;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)parseKeystoneTransactionWithQr:(NSArray<NSString *> *)qrDatas error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string>qrs;
        for (NSString *qr in qrDatas) {
            qrs.push_back([qr UTF8String]);
        }
        auto psbt = Utils::ParseKeystoneTransaction(qrs);
        return [NSString stringWithUTF8String:psbt.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getPartialSignatureWithSingleSigner:(ObjSingleSigner *)singleSigner psbt:(NSString *)psbt error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto signer = SingleSigner(std::string([singleSigner.signerName UTF8String]), std::string([singleSigner.xpub UTF8String]), std::string([singleSigner.publicKey UTF8String]), std::string([singleSigner.bip32Path UTF8String]), std::string([singleSigner.masterFingerPrint UTF8String]), false);
        signer.set_type([self parseObjCSignerType:singleSigner.type]);
        auto signature = Utils::GetPartialSignature(signer, [psbt UTF8String]);
        return [NSString stringWithUTF8String:signature.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
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

- (ObjAnalyzeQRResult *)importSignatureQRCode:(NSArray<NSString *> *)qrDatas error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string>qrs;
        for (NSString *qr in qrDatas) {
            qrs.push_back([qr UTF8String]);
        }
        auto psbt = Utils::AnalyzeQR(qrs);
        ObjAnalyzeQRResult *objResult = [[ObjAnalyzeQRResult alloc] init];
        objResult.isComplete = psbt.is_complete;
        objResult.isFailure = psbt.is_failure;
        objResult.isSuccess = psbt.is_success;
        objResult.processedPartsCount = psbt.processed_parts_count;        
        objResult.expectedPartCount = psbt.expected_part_count;
        objResult.estimatedPercentComplete = psbt.estimated_percent_complete;
        
        return objResult;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)sha256:(NSString *)string {
    return [NSString stringWithUTF8String: Utils::SHA256([string UTF8String]).c_str()];
}

- (BOOL)isAirgapTypeTag:(NSString *)tag {
    if ([tag isEqualToString:@"KEYSTONE"] || [tag isEqualToString:@"JADE"] || [tag isEqualToString:@"PASSPORT"] || [tag isEqualToString:@"SEEDSIGNER"] || [tag isEqualToString:@"COLDCARD"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isHardwareTypeTag:(NSString *)tag {
    if ([tag isEqualToString:@"TREZOR"] || [tag isEqualToString:@"LEDGER"] || [tag isEqualToString:@"COLDCARD"] || [tag isEqualToString:@"BITBOX"] || [tag isEqualToString:@"JADE"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isInheritanceTag:(NSString *)tag {
    if ([tag isEqualToString:@"INHERITANCE"]) {
        return YES;
    }
    return NO;
}

- (BOOL)IsValidDerivationPath:(NSString *)path {
    try {
        return Utils::IsValidDerivationPath([path UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSString *)exportSignedMessage:(NSString *)message address:(NSString *)address signature:(NSString *)signature error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::string ipMessage = [message UTF8String];
        std::string ipSignature = [signature UTF8String];
        std::string ipAddress = [address UTF8String];
        std::string signedMessage = ExportBitcoinSignedMessage(BitcoinSignedMessage(ipMessage, ipAddress, ipSignature));
        return [NSString stringWithUTF8String:signedMessage.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSString *)getFirstAddress:(NSString *)descriptor error:(NSError **)error {
    try {
        auto wallet = Utils::ParseWalletDescriptor([descriptor UTF8String]);
        std::vector<std::string> addresses = Utils::DeriveAddresses(wallet, 0, 0);
        if (addresses.size() == 1) {
            auto firstAddress = addresses[0];
            return [NSString stringWithUTF8String:firstAddress.c_str()];
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

- (BOOL)isValidAddress:(NSString *)address {
    try {
        return Utils::IsValidAddress([address UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSInteger)getIndexFromPath:(NSString *)path {
    try {
        return Utils::GetIndexFromPath([path UTF8String]);
    } catch (const std::exception& exception) {
        return -1;
    }
}

- (NSString *)psbtFromData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error {
    try {
        const unsigned char *dataArray = (unsigned char *)data.bytes;
        const size_t count = data.length / sizeof(unsigned char);
        std::string psbt(dataArray, dataArray + count);
        return [NSString stringWithUTF8String:psbt.c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjTransaction *)decodeDummyTxWithSigners:(NSArray<ObjSingleSigner *> *)signers psbt:(NSString *)psbt error:(NSError * _Nullable __autoreleasing *)error {
    try {
        Wallet wl = Wallet(false);
        std::vector<SingleSigner> remoteSigners;
        for(unsigned long i = 0; i < signers.count; i++) {
            ObjSingleSigner *rmSigner = [signers objectAtIndex:i];
            auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), std::string([rmSigner.masterFingerPrint UTF8String]), false);
            signer.set_type([self parseObjCSignerType:rmSigner.type]);
            remoteSigners.push_back(signer);
        }
        wl.set_signers(remoteSigners);
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

- (BOOL)isValidXPRV:(NSString *)xprv {
    try {
        return Utils::IsValidXPrv([xprv UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSString *)getBip32Path:(NSString *)walletType addressType:(NSString *)addressType index:(NSInteger)index error:(NSError * _Nullable __autoreleasing *)error {
    try {
        WalletType cWalletType = [self walletTypeFromString:walletType];
        AddressType cAddressType = [self addressTypeFromString:addressType];
        return [NSString stringWithUTF8String: Utils::GetBip32Path(cWalletType, cAddressType, index).c_str()];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [NSError errorWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (ObjSingleSigner *)parseSignerString:(NSString *)xpub error:(NSError * _Nullable __autoreleasing *)error {
    try {
        SingleSigner signer = Utils::ParseSignerString([xpub UTF8String]);
        return [[ObjSingleSigner alloc] initWithSigner:&signer];
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (BOOL)isExistingDecoyPin:(NSString *)storagePath pin:(NSString *)pin {
    try {
        return Utils::IsExistingDecoyPin([storagePath UTF8String], [pin UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (NSNumber *)changeDecoyPIN:(NSString *)storagePath oldPIN:(NSString *)oldPIN newPIN:(NSString *)newPIN error:(NSError * _Nullable __autoreleasing *)error {
    try {
        auto result = Utils::ChangeDecoyPin([storagePath UTF8String], [oldPIN UTF8String], [newPIN UTF8String]);
        return [NSNumber numberWithBool:result];
    }  catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)exportKeystoneWallet:(ObjWallet *)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner>signers;
        for (NSUInteger i = 0; i < wallet.signers.count; i++) {
            if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                signers.push_back(signer);
            }
        }
        AddressType addressType = [self addressTypeFromString: wallet.addressType];
        auto obj = Wallet([wallet.walletId UTF8String], [wallet.walletName UTF8String], wallet.m, wallet.n, signers, addressType, wallet.isEscrow, [wallet.createdAt timeIntervalSince1970]);
        auto datas = Utils::ExportKeystoneWallet(obj, fragmentLength);
        NSMutableArray *keystones = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [keystones addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return keystones;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)exportBCUR2:(ObjWallet *)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner>signers;
        for (NSUInteger i = 0; i < wallet.signers.count; i++) {
            if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                signers.push_back(signer);
            }
        }
        AddressType addressType = [self addressTypeFromString: wallet.addressType];
        auto obj = Wallet([wallet.walletId UTF8String], [wallet.walletName UTF8String], wallet.m, wallet.n, signers, addressType, wallet.isEscrow, [wallet.createdAt timeIntervalSince1970]);
        auto datas = Utils::ExportBCR2020010Wallet(obj, fragmentLength);
        NSMutableArray *qrs = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [qrs addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return qrs;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

- (NSArray *)exportBBQRWallet:(ObjWallet *)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<SingleSigner>signers;
        for (NSUInteger i = 0; i < wallet.signers.count; i++) {
            if ([[wallet.signers objectAtIndex:i] isKindOfClass:[ObjSingleSigner class]]) {
                ObjSingleSigner *rmSigner = [wallet.signers objectAtIndex:i];
                auto signer = SingleSigner(std::string([rmSigner.signerName UTF8String]), std::string([rmSigner.xpub UTF8String]), std::string([rmSigner.publicKey UTF8String]), std::string([rmSigner.bip32Path UTF8String]), std::string([rmSigner.masterFingerPrint UTF8String]), false);
                signer.set_type([self parseObjCSignerType:rmSigner.type]);
                signers.push_back(signer);
            }
        }
        AddressType addressType = [self addressTypeFromString: wallet.addressType];
        auto obj = Wallet([wallet.walletId UTF8String], [wallet.walletName UTF8String], wallet.m, wallet.n, signers, addressType, wallet.isEscrow, [wallet.createdAt timeIntervalSince1970]);
        auto datas = Utils::ExportBBQRWallet(obj, ExportFormat::COLDCARD, 1, fragmentLength);
        NSMutableArray *bbqrs = [[NSMutableArray alloc] init];
        for (auto &data: datas) {
            [bbqrs addObject: [NSString stringWithUTF8String:data.c_str()]];
        }
        return bbqrs;
    } catch (const BaseException& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    } catch (const std::exception& exception) {
        *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        return NULL;
    }
}

//
// Miniscript utilities
//
- (BOOL)isValidMiniscriptTemplate:(NSString *_Nonnull)tmpl addressType:(NSString *_Nonnull)addressType {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        return Utils::IsValidMiniscriptTemplate([tmpl UTF8String], cAddressType);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (BOOL)isValidPolicy:(NSString *_Nonnull)policy {
    try {
        return Utils::IsValidPolicy([policy UTF8String]);
    } catch (const std::exception& exception) {
        return NO;
    }
}

- (BOOL)isValidTapscriptTemplate:(NSString *_Nonnull)tmpl error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::string err;
        bool result = Utils::IsValidTapscriptTemplate([tmpl UTF8String], err);
        if (!result && error && !err.empty()) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{ @"message": [NSString stringWithUTF8String:err.c_str()] }];
            return NO;
        }
        return result;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code:NunchukSDKErrorUndefined userInfo:@{ @"message": [NSString stringWithUTF8String:exception.what()] }];
        }
        return NO;
    }
}

- (NSString *_Nullable)policyToMiniscript:(NSString *_Nonnull)policy addressType:(NSString *_Nonnull)addressType error:(NSError * _Nullable __autoreleasing *)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        std::string result = Utils::PolicyToMiniscript([policy UTF8String], {}, cAddressType);
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const BaseException& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    }
}

- (NSDictionary *_Nullable)getScriptNode:(NSString *_Nonnull)script error:(NSError * _Nullable __autoreleasing *)error {
    try {
        std::vector<std::string> keypaths;
        auto scriptNode = Utils::GetScriptNode([script UTF8String], keypaths);
        ObjScriptNode *objScriptNode = [[ObjScriptNode alloc] initWithScriptNode:scriptNode];
        NSMutableArray * keypathsArr = [[NSMutableArray alloc] init];
        for(auto& keypath : keypaths) {
            [keypathsArr addObject:[[NSString alloc] initWithUTF8String: keypath.c_str()]];
        }
        return @{ @"scriptNode": objScriptNode, @"keyPaths": keypathsArr };
    } catch (const BaseException& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    }
}

- (Timelock::Type)timelockTypeFromString: (NSString *)timelockType {
    if (std::strcmp([timelockType UTF8String], "absolute") == 0) {
        return Timelock::Type::ABSOLUTE;
    }
    
    if (std::strcmp([timelockType UTF8String], "relative") == 0) {
        return Timelock::Type::RELATIVE;
    }
    
    return Timelock::Type::ABSOLUTE;
}

- (Timelock::Based)timelockUnitFromString: (NSString *)timelockUnit {
    if (std::strcmp([timelockUnit UTF8String], "timestamp") == 0) {
        return Timelock::Based::TIME_LOCK;
    }
    
    if (std::strcmp([timelockUnit UTF8String], "blockHeight") == 0) {
        return Timelock::Based::HEIGHT_LOCK;
    }
    
    return Timelock::Based::HEIGHT_LOCK;
}

- (ObjTimeLock *)timelockFromK: (long)k isAbsolute:(BOOL)isAbsolute {
    Timelock timelock = Timelock::FromK(isAbsolute, k);
    return [[ObjTimeLock alloc] initWithTimelock:&timelock];
}

- (NSString *_Nullable)expandingMultisigMiniscriptTemplate:(int)m n:(int)n newN:(int)newN reuseSigners:(BOOL)reuseSigners expandTime:(long)expandTime timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        Timelock::Based cTimelockUnit = [self timelockUnitFromString:timelockUnit];
        Timelock::Type cTimelockType = [self timelockTypeFromString:timelockType];
        Timelock timelock(cTimelockUnit, cTimelockType, expandTime);
        std::string result = Utils::ExpandingMultisigMiniscriptTemplate(m, n, newN, reuseSigners, timelock, cAddressType);
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const BaseException& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    }
}

- (NSString *_Nullable)decayingMultisigMiniscriptTemplate:(int)m n:(int)n newM:(int)newM reuseSigners:(BOOL)reuseSigners decayTime:(long)decayTime timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        Timelock::Based cTimelockUnit = [self timelockUnitFromString:timelockUnit];
        Timelock::Type cTimelockType = [self timelockTypeFromString:timelockType];
        Timelock timelock(cTimelockUnit, cTimelockType, decayTime);
        std::string result = Utils::DecayingMultisigMiniscriptTemplate(m, n, newM, reuseSigners, timelock, cAddressType);
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const BaseException& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    }
}

- (NSString *_Nullable)flexibleMultisigMiniscriptTemplate:(int)m n:(int)n newM:(int)newM newN:(int)newN reuseSigners:(BOOL)reuseSigners time:(long)time timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error {
    try {
        AddressType cAddressType = [self addressTypeFromString:addressType];
        Timelock::Based cTimelockUnit = [self timelockUnitFromString:timelockUnit];
        Timelock::Type cTimelockType = [self timelockTypeFromString:timelockType];
        Timelock timelock(cTimelockUnit, cTimelockType, time);
        std::string result = Utils::FlexibleMultisigMiniscriptTemplate(m, n, newM, newN, reuseSigners, timelock, cAddressType);
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const BaseException& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: exception.code() userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    } catch (const std::exception& exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"io.nunchuk.ios" code: NunchukSDKErrorUndefined userInfo:@{@"message": [NSString stringWithUTF8String: exception.what()]}];
        }
        return nil;
    }
}

- (NSDictionary *_Nullable)getScriptNodeSatisfiable:(NSString *_Nonnull)script psbt:(NSString *_Nonnull)psbt {
    try {
        std::vector<std::string> keypaths;
        auto scriptNode = Utils::GetScriptNode([script UTF8String], keypaths);
        return [self getNodeSatisfiable:scriptNode psbt:psbt];
    } catch (const BaseException& exception) {
        return nil;
    }
}

- (NSDictionary *)getNodeSatisfiable:(const ScriptNode &)node psbt:(NSString *_Nonnull)psbt {
    const std::vector<size_t>& nodeId = node.get_id();
    NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:nodeId.size()];
    for (size_t idValue : nodeId) {
        [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
    }
    NSString *nodeIdStr = [idArray componentsJoinedByString:@"."];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[NSNumber numberWithBool:node.is_satisfiable([psbt UTF8String])] forKey:nodeIdStr];
    
    const std::vector<ScriptNode>& subs = node.get_subs();
    for (const ScriptNode& subNode : subs) {
        NSDictionary *subDict = [self getNodeSatisfiable:subNode psbt:psbt];
        [dict addEntriesFromDictionary:subDict];
    }
    return dict;
}

@end
