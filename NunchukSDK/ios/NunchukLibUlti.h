//
//  NunchukLibUlti.h
//  nunchukSDK
//
//  Created by Thai Nguyen on 5/30/22.
//

#ifndef NunchukLibUlti_h
#define NunchukLibUlti_h

#import "ObjAppSettings.h"
#import "ObjBtcUri.h"
#import "ObjTransaction.h"
#import "ObjWallet.h"
#import "ObjSingleSigner.h"
#import <CoreNFC/CoreNFC.h>
#import "ObjAnalyzeQRResult.h"
#import "ObjScriptNode.h"

typedef enum NCNDEFMessageType {
    UNKNOWN,
    TAPSIGNER,
    SATSCARD,
    JSON,
    PSBT,
    TRANSACTION,
    ADDRESS,
    MULTIPLE_ADDRESSES,
    TEXT,
    WALLET
} NCNDEFMessageType;

@interface NunchukLibUlti: NSObject

+ (instancetype _Nonnull)shared;
- (NSString *_Nullable)generateMnemonic;
- (NSString *_Nullable)generateMnemonic12Words;
- (NSString *_Nullable)getPrimaryKeyAddressWithMnemonic:(NSString *_Nonnull)mnemonic passphrase:(NSString *_Nonnull)passphrase;
- (NSString *_Nullable)getPrimaryKeyAddressWithXPRV:(NSString *_Nonnull)xprv;
- (NSString *_Nullable)signLoginMessageWithMnemonic:(NSString *_Nonnull)mnemonic passphrase:(NSString *_Nonnull)passphrase message:(NSString *_Nonnull)message;
- (NSString *_Nullable)signLoginMessageWithXPRV:(NSString *_Nonnull)xprv message:(NSString *_Nonnull)message;
- (BOOL)isMnemonicValid:(NSString *_Nonnull)mnemonic;
- (NSArray *_Nullable)getBip39:(NSError * _Nullable*_Nullable)error;
- (NSString *_Nullable)getMasterFingerprintWithMnemonic:(NSString *_Nonnull)mnemonic passphrase:(NSString *_Nonnull)passphrase;
- (NSString *_Nullable)getMasterFingerprintWithXPRV:(NSString *_Nonnull)xprv;
- (NSArray *_Nullable)getPrimaryKeysWithStoragePath:(NSString *_Nonnull)storagePath chain:(ChainTypeEnum)chain;
- (UInt64)amountFromValue:(NSString *_Nonnull)value;
- (NSString *_Nonnull)valueFromAmount:(UInt64)amount;
- (ObjBtcUri *_Nullable)parseBtcUri:(NSString *_Nonnull)qr error:(NSError * _Nullable*_Nullable)error;
- (NCNDEFMessageType)getNDEFType:(NSArray *_Nonnull)records;
- (NSString *_Nullable)ndefRecordToJson:(NFCNDEFPayload *_Nonnull)record;
- (NSArray *_Nullable)ndefRecordFromString:(NSString *_Nonnull)data;
- (NSString *_Nullable)ndefRecordToString:(NFCNDEFPayload *_Nonnull)record;
- (NSArray *_Nullable)ndefRecordFromPSBT:(NSString *_Nonnull)data;
- (NSString *_Nullable)ndefRecordToPSBT:(NSArray *_Nonnull)records;
- (NSString *_Nullable)ndefRecordToRawTransaction:(NSArray *_Nonnull)records;
- (BOOL)setChain:(ChainTypeEnum)chain;
- (ChainTypeEnum)getChain;
- (NSArray *_Nullable)generateColdCardHealthCheckNDEFMessage:(NSString *_Nonnull)path;
- (NSString *_Nonnull)createRequestTokenWithSignature:(NSString *_Nonnull)signature fingerprint:(NSString *_Nonnull)fingerprint;
- (NSString *_Nonnull)getHealthCheckMessageWithBody:(NSString *_Nonnull)body;
- (NSArray<NSString *> *_Nullable)exportKeystoneTransactionWithPsbt:(NSString *_Nonnull)psbt fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)error;
- (NSArray<NSString *> *_Nullable)exportBBQRTransactionWithPsbt:(NSString *_Nonnull)psbt fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)parseKeystoneTransactionWithQr:(NSArray<NSString *> *_Nonnull)qrDatas error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getPartialSignatureWithSingleSigner:(ObjSingleSigner *_Nonnull)singleSigner psbt:(NSString *_Nonnull)psbt error:(NSError *_Nullable*_Nullable)error;
- (ObjAnalyzeQRResult *_Nullable)importSignatureQRCode:(NSArray<NSString *> *_Nonnull)qrDatas error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nonnull)sha256:(NSString *_Nonnull)string;
- (BOOL)isAirgapTypeTag:(NSString *_Nonnull)tag;
- (BOOL)isHardwareTypeTag:(NSString *_Nonnull)tag;
- (BOOL)isInheritanceTag:(NSString *_Nonnull)tag;
- (BOOL)IsValidDerivationPath:(NSString *_Nonnull)path;
- (NSString *_Nullable)exportSignedMessage:(NSString *_Nonnull)message address:(NSString *_Nonnull)address signature:(NSString *_Nonnull)signature error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getFirstAddress:(NSString *_Nonnull)descriptor error:(NSError *_Nullable*_Nullable)error;
- (BOOL)isValidAddress:(NSString *_Nonnull)address;
- (NSInteger)getIndexFromPath:(NSString *_Nonnull)path;
- (NSString *_Nullable)psbtFromData:(NSData *_Nonnull)data error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)decodeDummyTxWithSigners:(NSArray<ObjSingleSigner*> *_Nonnull)signers psbt:(NSString *_Nonnull)psbt error:(NSError *_Nullable*_Nullable)error;
- (BOOL)isValidXPRV:(NSString *_Nonnull)xprv;
- (NSString *_Nullable)getBip32Path:(NSString *_Nonnull)walletType addressType:(NSString *_Nonnull)addressType index: (NSInteger)index error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)parseSignerString:(NSString *_Nonnull)xpub error:(NSError *_Nullable*_Nullable)error;
- (BOOL)isExistingDecoyPin:(NSString *_Nonnull)storagePath pin:(NSString *_Nonnull)pin;
- (NSNumber *_Nullable)changeDecoyPIN:(NSString *_Nonnull)storagePath oldPIN:(NSString *_Nonnull)oldPIN newPIN:(NSString *_Nonnull)newPIN error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)exportKeystoneWallet:(ObjWallet *_Nonnull)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)exportBCUR2:(ObjWallet *_Nonnull)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)exportBBQRWallet:(ObjWallet *_Nonnull)wallet fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)error;

// Miniscript utilities
- (BOOL)isValidMiniscriptTemplate:(NSString *_Nonnull)tmpl addressType:(NSString *_Nonnull)addressType;
- (BOOL)isValidPolicy:(NSString *_Nonnull)policy;
- (BOOL)isValidTapscriptTemplate:(NSString *_Nonnull)tmpl error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)policyToMiniscript:(NSString *_Nonnull)policy addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)miniscriptTemplateToMiniscript:(NSString *_Nonnull)tmpl signers:(NSDictionary<NSString *, ObjSingleSigner *> *_Nonnull)signers error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)getScriptNode:(NSString *_Nonnull)script error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)expandingMultisigMiniscriptTemplate:(int)m n:(int)n newN:(int)newN reuseSigners:(BOOL)reuseSigners expandTime:(int)expandTime timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)decayingMultisigMiniscriptTemplate:(int)m n:(int)n newM:(int)newM reuseSigners:(BOOL)reuseSigners decayTime:(int)decayTime timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)flexibleMultisigMiniscriptTemplate:(int)m n:(int)n newM:(int)newM newN:(int)newN reuseSigners:(BOOL)reuseSigners time:(int)time timelockType:(NSString *_Nonnull)timelockType timelockUnit:(NSString *_Nonnull)timelockUnit addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;

@end

#endif /* NunchukLibUlti_h */
