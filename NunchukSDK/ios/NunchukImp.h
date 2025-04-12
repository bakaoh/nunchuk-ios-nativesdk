#ifndef nunchukimp
#define nunchukimp
#include "ObjDevice.h"
#include "ObjSingleSigner.h"
#include "ObjWallet.h"
#include "ObjMasterSigner.h"
#include "ObjTransaction.h"
#import <Foundation/Foundation.h>
#include "ObjUnspentOutput.h"
#import "ObjNunchukMatrixEvent.h"
#import "ObjRoomWallet.h"
#import "ObjRoomTransaction.h"
#import "ObjAppSettings.h"
#import "ObjPrimaryKey.h"
#import <CoreNFC/CoreNFC.h>
#import "ObjTapsignerStatus.h"
#import "ObjSatscardSlot.h"
#import "ObjSatscardStatus.h"
#import "ObjTapCardResult.h"
#import "ObjAssistedWallet.h"
#import "ObjKeyInfo.h"
#import "ObjTapSignerKeyInfo.h"
#import "ObjRemoteTransaction.h"
#import "ObjCoinTag.h"
#import "ObjCoinCollection.h"
#import "ObjSignMessage.h"
#import "ObjDraftTransaction.h"
#import "ObjWalletData.h"
#import "ObjDraftRolloverTransaction.h"
#import "ObjBSMSData.h"
#import "ObjKeySetStatus.h"
#import "ObjGroupMessage.h"
#import "ObjGroupConfig.h"
#import "ObjGroupWalletConfig.h"
#import "ObjGroupSandbox.h"

typedef enum NunchukSDKError: NSInteger {
    NunchukSDKErrorUndefined = -1000000,
    NunchukSDKErrorCancelNFCSession = -1000001,
    NunchukSDKErrorSignerExist = -1000002,
    NunchukSDKErrorShouldHandleAsPortal= -1000003,
    NunchukSDKErrorGroupSandboxFinalized= -1000004
} NunchukSDKError;

typedef enum ConnectionStatusEnum {
    OFFLINE,
    SYNCING,
    ONLINE
} ConnectionStatusEnum;

typedef enum NunchukExportFormat {
    DB,
    DESCRIPTOR,
    COLDCARD,
    COBO,
    CSV,
    BSMS
} NunchukExportFormat;

typedef enum KeyHealthStatus {
    SUCCESS,
    FINGERPRINT_NOT_MATCHED,
    NO_SIGNATURE,
    SIGNATURE_INVALID,
    KEY_NOT_MATCHED
} KeyHealthStatus;

extern const int FEE_RATE_PRIORITY;
extern const int FEE_RATE_STANDARD;
extern const int FEE_RATE_ECONOMICAL;

@protocol NunchukSDKDelegate <NSObject>
@optional
- (NSString* _Nullable)sendEventWithRoomId:(NSString* _Nonnull)roomId
                                  evenType:(NSString* _Nonnull)eventType
                                   content:(NSString* _Nonnull)content
                               ignoreError: (BOOL)ignoreError;
- (void)didReceiveUploadRequestWithRoomId:(NSString* _Nonnull)roomId
                                 fileName:(NSString* _Nonnull)fileName
                                 mineType:(NSString* _Nonnull)mineType
                             fileJsonInfo:(NSString* _Nonnull)fileJsonInfo
                                     data:(NSData* _Nonnull)data;
- (void)didReceiveDownloadRequestWithFileName:(NSString* _Nonnull)fileName
                                     mineType:(NSString* _Nonnull)mineType
                                 fileJsonInfo:(NSString* _Nonnull)fileJsonInfo
                                       mxcUri:(NSString* _Nonnull)mxcUri;
- (void)didUpdateConnectionStatus:(ConnectionStatusEnum)status syncProgress:(NSInteger)syncProgress;
- (void)didUpdateBlock:(NSInteger)height hexHeader:(NSString* _Nonnull)hexHeader;
- (void)didUpdateWalletBalance:(double)balance walletId:(NSString *_Nonnull)walletId;
- (void)didUpdateTransaction:(NSString *_Nonnull)transactionId walletId:(NSString *_Nonnull)walletId status:(NSString *_Nonnull)status;
- (void)didReceiveGroupMessage:(ObjGroupMessage *_Nonnull)message;
- (void)didUpdateGroupSanbox:(ObjGroupSandbox *_Nonnull)groupSandbox;
- (void)didUpdateGroupOnline:(NSString *_Nonnull)groupId online:(NSInteger)online;
- (void)didDeletedGroupSandbox:(NSString *_Nonnull)groupId;
- (void)didReceiveReplaceRequest:(NSString *_Nonnull)walletId replaceGroupId:(NSString *_Nonnull)replaceGroupId;

@end
@interface NunchukImp :NSObject
@property (nonatomic, weak)id <NunchukSDKDelegate> _Nullable delegate;
-(BOOL)importWallet:(NSBundle*_Nonnull)bundle error:(NSError * _Nullable * _Nullable)outError;
-(NSString* _Nullable)createWalletWithName:(NSString* _Nullable)name numberKey:(int)numberKey signers:(NSMutableArray * _Nonnull)signers addressType:(NSString *_Nonnull)addressType type:(NSString *_Nonnull)type error:(NSError * _Nullable * _Nullable)outError;
- (NSString *_Nullable)createTaprootWalletWithName:(NSString *_Nonnull)name numberKey:(int)numberKey signers:(NSMutableArray *_Nonnull)signers type:(NSString *_Nonnull)type valueKeyEnabled:(BOOL)valueKeyEnabled error:(NSError *_Nullable*_Nullable)error;
- (ObjWallet *_Nullable)createDecoyWallet:(NSString *_Nonnull)name numberKey:(int)numberKey signers:(NSMutableArray *_Nonnull)signers addressType:(NSString *_Nonnull)addressType type:(NSString *_Nonnull)type pin:(NSString *_Nonnull)pin error:(NSError *_Nullable*_Nullable)error;
- (ObjWallet *_Nullable)createDecoyWallet:(NSString *_Nonnull)pin fromWalletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
-(ObjWallet* _Nullable)createHotWallet:(NSString * _Nonnull)passphrase error:(NSError * _Nullable * _Nullable)outError;
-(ObjWallet *_Nullable)recoverHotWallet:(NSString* _Nonnull)mnemonic passphrase:(NSString *_Nonnull)passphrase replace:(BOOL)replace error:(NSError * _Nullable * _Nullable)outError;
-(NSString * _Nullable)getHotWalletMnemonic:(NSString *_Nonnull)walletId passphrase:(NSString *_Nonnull)passphrase error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)confirmMnemonicHotWallet:(NSString * _Nonnull)walletId mnemonic:(NSString* _Nonnull)mnemonic passphrase:(NSString * _Nonnull)passphrase error:(NSError * _Nullable * _Nullable)outError;
-(NSString*_Nullable)draftWalletWithName:(NSString* _Nullable)name numberKey:(int)numberKey signers:(NSMutableArray * _Nonnull)signers addressType:(NSString *_Nullable)addressType type:(NSString * _Nullable)type desc:(NSString * _Nullable)desc error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)consumeEvent:(ObjNunchukMatrixEvent *_Nonnull)event error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateWalletNameWithId:(NSString * _Nonnull)walletId name:(NSString * _Nonnull)name error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateWalletGapLimitWithId:(NSString * _Nonnull)walletId limit:(int)limit error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateSignerName:(NSString* _Nullable)name path:(NSString *_Nullable)path fingerprint:(NSString *_Nullable)fingerPrint error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateSignerName:(NSString* _Nullable)name signerId:(NSString* _Nullable)signerId error:(NSError * _Nullable * _Nullable)outError;

-(BOOL)removeSignerWithPath:(NSString *_Nullable)path fingerprint:(NSString *_Nullable)fingerPrint error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)removeSignerWithId:(NSString *_Nullable)signerId error:(NSError * _Nullable * _Nullable)outError;
-(ObjSingleSigner *_Nullable)newRemoteSignerWithName:(NSString *_Nullable)name xpub:(NSString *_Nullable)xPub xpubKey:(NSString *_Nullable)xPubkey path:(NSString *_Nullable)path fingerprint:(NSString *_Nullable)fingerPrint tags:(NSArray<NSString *>*_Nullable)tags error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)exportWalletWithId:(NSString* _Nonnull)walletId filePath:(NSString* _Nonnull)filePath format:(NSString* _Nonnull)walletFormat error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)createNewMasterSignerWithName:(NSString * _Nonnull)name device:(ObjDevice * _Nonnull)device error:(NSError * _Nullable * _Nullable)outError;
-(NSMutableArray<ObjSingleSigner *> *_Nullable)getSigners:(NSError * _Nullable * _Nullable)outError;
-(NSMutableArray<ObjWallet *> *_Nullable)getWallets:(BOOL)ordered error:(NSError * _Nullable * _Nullable)outError;
-(ObjWallet *_Nullable)getWalletWithId:(NSString *_Nonnull)walletId error:(NSError * _Nullable * _Nullable)outError;
-(NSString * _Nullable)generateMnemonic:(NSError * _Nullable * _Nullable)outError;
-(ObjMasterSigner*_Nullable)createSoftwareSignerWithName:(NSString * _Nonnull)raw_name mnemonic:(NSString * _Nonnull)mnemonic passphrase:(NSString * _Nonnull)passphrase replace:(BOOL)replace error:(NSError * _Nullable * _Nullable)outError;
- (ObjMasterSigner *_Nullable)createSoftwareSignerFromMasterXprv:(NSString *_Nonnull)xprv name:(NSString *_Nonnull)name replace:(BOOL)replace error:(NSError *_Nullable*_Nullable)error;
- (ObjMasterSigner *_Nullable)createHotKeyWithName:(NSString *_Nonnull)name error:(NSError *_Nullable*_Nullable)error;
- (ObjMasterSigner *_Nullable)create12WordsHotKeyWithName:(NSString *_Nonnull)name error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getHotKeyMnemonicWithSignerId:(NSString *_Nonnull)signerId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)setSignerNeedBackup:(NSString *_Nonnull)signerId needBackup:(BOOL)needBackup error:(NSError *_Nullable*_Nullable)error;
- (ObjMasterSigner *_Nullable)createPrimaryKeyWithName:(NSString *_Nonnull)name mnemonic:(NSString *_Nonnull)mnemonic passphrase:(NSString *_Nonnull)passphrase error:(NSError  *_Nullable*_Nullable)outError;
-(ObjMasterSigner* _Nullable)getSignerWithId:(NSString * _Nonnull)signerId error:(NSError * _Nullable * _Nullable)outError;
-(NSMutableArray<ObjMasterSigner*> * _Nullable)getMasterSigners:(NSError * _Nullable * _Nullable)outError;
-(NSMutableArray<NSString*> *_Nullable)getBip39:(NSError * _Nullable * _Nullable)outError;
-(NSArray<ObjTransaction*> *_Nullable)getTransactionsWithWalletId:(NSString * _Nonnull)walletId error:(NSError * _Nullable * _Nullable)outError;
-(ObjTransaction *_Nullable)getTransactionWithWalletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError * _Nullable * _Nullable)outError;
-(NSArray<NSString*> *_Nullable)getAddressWithWalletId:(NSString * _Nonnull)walletId used:(BOOL)used internal:(BOOL)internal error:(NSError * _Nullable * _Nullable)outError;
-(NSInteger)getAddressBalanceWithWalletId:(NSString * _Nonnull)walletId address:(NSString *_Nonnull)address error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)markAddressAsUsedWithWalletId:(NSString * _Nonnull)walletId address:(NSString *_Nonnull)address error:(NSError * _Nullable * _Nullable)outError;
-(NSString * _Nullable)getAddressPathWithWalletId:(NSString * _Nonnull)walletId address:(NSString *_Nonnull)address error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)isMnemonicValid:(NSString * _Nonnull)mnemonic error:(NSError * _Nullable * _Nullable)outError;
-(ObjDraftTransaction* _Nullable)draftTransactionWithWalletId:(NSString * _Nonnull)walletId outputs:(NSArray<StringIntPair*> *_Nonnull)outputs inputs:(NSArray<ObjUnspentOutput*> *_Nonnull)input feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError * _Nullable * _Nullable)outError;

-(ObjTransaction* _Nullable)broadcastTransactionWithWalletId:(NSString * _Nonnull)walletId txId:(NSString * _Nonnull)txId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateTransactionMemoWithWalletId:(NSString * _Nonnull)walletId txId:(NSString * _Nonnull)txId newMemo:(NSString * _Nullable)newMemo error:(NSError * _Nullable * _Nullable)outError;
-(NSInteger)estimatFee:(NSError * _Nullable * _Nullable)outError;
-(NSInteger)estimatFeeWithConfig:(int)conf error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)deleteTransactionWithWalletId:(NSString *_Nonnull)walletId txId:(NSString * _Nullable)transactionId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)deleteWalletWithWalletId:(NSString *_Nonnull)walletId error:(NSError * _Nullable * _Nullable)outError;
-(NSString *_Nullable)newAddressWithWalletId:(NSString * _Nullable)walletId error:(NSError * _Nullable * _Nullable)outError;
-(ObjWallet *_Nullable)importBSMSWithFilePath:(NSString* _Nonnull)filePath walletName:(NSString* _Nonnull)walletName error:(NSError * _Nullable * _Nullable)outError;

-(ObjTransaction *_Nullable)createTransactionWithWalletId:(NSString * _Nonnull)walletId outputs:(NSArray<StringIntPair*> *_Nullable)outputs memo:(NSString * _Nonnull)memo feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount inputs:(NSArray *_Nonnull)inputs antiFeeSniping:(BOOL)antiFeeSniping error:(NSError * _Nullable * _Nullable)outError;
-(ObjTransaction *_Nullable)signTransactionWithWalletId:(NSString * _Nonnull)walletId txId:(NSString * _Nonnull)txId fingerprint:(NSString * _Nonnull)fingerPrint error:(NSError * _Nullable * _Nullable)outError;
-(NSInteger)getTotalAmountWithWalletId:(NSString * _Nonnull)walletId txId:(NSString * _Nonnull)txId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)sendPassphrase:(NSString * _Nonnull)passphrase signerId:(NSString *_Nonnull)signerId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)setupNunchukWithAccount:(NSString * _Nullable)account passPhrase:(NSString * _Nullable)passphrase settings:(ObjAppSettings * _Nullable)settings deviceId:(NSString *_Nonnull)deviceId setupListener:(BOOL)setupListener error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)setupNunchukWithDecoyPIN:(NSString *_Nonnull)pin settings:(ObjAppSettings *_Nullable)settings setupListener:(BOOL)setupListener error:(NSError *_Nullable*_Nullable)error;
-(NSInteger)getChainTip:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent * _Nullable)initializeWalletWithRoomId:(NSString *_Nonnull)roomId name:(NSString *_Nonnull)name min:(int)m total:(int)n addressType:(NSString *_Nonnull)addressType isEscrow:(BOOL)isEsrow desc:(NSString * _Nullable)desc error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)joinWalletWithRoomId:(NSString *_Nonnull)roomId signers:(NSArray *_Nonnull)signers walletType:(NSString *_Nonnull)walletTypeStr addressType:(NSString *_Nonnull)addressTypeStr error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent * _Nullable)leaveWalletWithRoomId:(NSString *_Nonnull)roomId joinId:(NSString *_Nonnull)joinId reason:(NSString *_Nonnull)reason error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent * _Nullable)createWalletWithRoomId:(NSString *_Nonnull)roomId error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent * _Nullable)cancelWalletWithRoomId:(NSString *_Nonnull)roomId reason:(NSString *_Nonnull)reason error:(NSError * _Nullable * _Nullable)outError;
-(ObjRoomWallet *_Nullable)getRoomWalletWithRoomId:(NSString *_Nonnull)roomId error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)getEventWithEventId:(NSString *_Nonnull)eventId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)consumeSyncEvent:(ObjNunchukMatrixEvent *_Nonnull)event withProgress:(BOOL (^_Nullable)(int))consumeProgress error:(NSError * _Nullable*_Nullable)outError;
-(BOOL)registerAutoBackupWithRoomId:(NSString *_Nonnull)roomId accessToken:(NSString *_Nonnull)accessToken error:(NSError *_Nullable*_Nullable)outError;
- (BOOL)enableAutoBackup:(BOOL)enabled error:(NSError *_Nullable*_Nullable)outError;
- (BOOL)backupWithError:(NSError *_Nullable*_Nullable)outError;
-(BOOL)backupFileWithFileJsonInfo:(NSString * _Nonnull)fileJsonInfo fileURL:(NSString * _Nonnull)fileURL error:(NSError * _Nullable *_Nullable)outError;
-(BOOL)registerDownloadAndUploadFile:(NSError * _Nullable *_Nullable)outError;
-(BOOL)consumeSyncFileWith:(NSString * _Nonnull)fileJsonInfo filePath:(NSString *_Nonnull)filePath withProgressBlock:(BOOL (^_Nullable)(int))progressBlock error:(NSError *_Nullable*_Nullable)outError;
-(NSArray<ObjRoomWallet *> *_Nullable)getAllRoomWallets:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)initialzeTransactionWithRoomId:(NSString *_Nonnull)roomId outputs:(NSArray<StringIntPair *> *_Nonnull)outputs memo:(NSString *_Nullable)memo inputs:(NSArray<ObjUnspentOutput *> *_Nonnull)inputs feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)signTransactionWithInitEventId:(NSString *_Nonnull)initEventId device:(ObjDevice *_Nullable)device error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)rejectTransactionWithInitEventId:(NSString *_Nonnull)initEventId reason:(NSString *_Nullable)reason error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)cancelTransactionWithInitEventId:(NSString *_Nonnull)initEventId reason:(NSString *_Nullable)reason error:(NSError * _Nullable * _Nullable)outError;
-(ObjNunchukMatrixEvent *_Nullable)broadcastTransactionWithInitEventId:(NSString *_Nonnull)initEventId error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)enableGenerateReceiveEvent:(NSError * _Nullable * _Nullable)outError;
-(NSArray<ObjRoomTransaction *> *_Nullable)getPendingTransactionsWithRoomId:(NSString *_Nonnull)roomId error:(NSError * _Nullable * _Nullable)outError;
-(ObjRoomTransaction *_Nullable)getRoomTransactionWithInitEventId:(NSString *_Nonnull)initEventId error:(NSError * _Nullable * _Nullable)outError;
-(NSString *_Nullable)getTransactionIdWithEventId:(NSString *_Nonnull)eventId error:(NSError * _Nullable * _Nullable)outError;
-(ObjAppSettings *_Nullable)getNetworkSettings:(NSError * _Nullable * _Nullable)outError;
-(BOOL)updateSettings:(ObjAppSettings *_Nonnull)settings error:(NSError * _Nullable * _Nullable)outError;

// Keystone
-(NSArray<NSString *>*_Nullable)exportKeystoneWalletWithId:(NSString *_Nonnull)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable * _Nullable)outError;
-(ObjWallet *_Nullable)importKeystoneWalletWithQrs:(NSArray<NSString *>*_Nonnull)qrDatas description:(NSString *_Nonnull)description error:(NSError * _Nullable * _Nullable)outError;
-(NSArray<NSString *>*_Nullable)exportKeystoneTransactionWithWalletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable * _Nullable)outError;
-(ObjTransaction *_Nullable)importKeystoneTransactionWithWalletId:(NSString *_Nonnull)walletId qrData:(NSArray<NSString *>*_Nonnull)qrDatas error:(NSError * _Nullable * _Nullable)outError;

-(ObjTransaction *_Nullable)importPSBTWith:(NSString *_Nonnull)walletId base64Pspt:(NSString *_Nonnull)psbt error:(NSError * _Nullable * _Nullable)outError;
-(BOOL)exportTransaction:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId filePath:(NSString *_Nonnull)filePath error:(NSError * _Nullable * _Nullable)outError;
-(ObjTransaction *_Nullable)importTransaction:(NSString *_Nonnull)walletId filePath:(NSString *_Nonnull)filePath error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)healthCheckMasterSigner:(ObjMasterSigner *_Nonnull)signer
                        message:(NSString *_Nullable)message
                      signature:(NSString *_Nullable)signature
                           path:(NSString *_Nullable)path
                          error:(NSError *_Nullable*_Nullable)error;
- (BOOL)healthCheckSingleSigner:(ObjSingleSigner *_Nonnull)signer
                        message:(NSString *_Nullable)message
                      signature:(NSString *_Nullable)signature
                          error:(NSError *_Nullable*_Nullable)error;
- (BOOL)sendErrorEvent:(NSString *_Nonnull)roomId
              platform:(NSString *_Nonnull)platform
                  code:(NSString *_Nullable)code
               message:(NSString *_Nullable)message
                 error:(NSError *_Nullable*_Nullable)error;
- (BOOL)hasRoomWallet:(NSString *_Nonnull)roomId;
- (NSString *_Nullable)signLoginMessageWithKeyId:(NSString *_Nonnull)keyId message:(NSString *_Nonnull)message;
- (BOOL)deletePrimaryKeyWithError:(NSError *_Nullable*_Nullable)outError;
- (ObjWallet *_Nullable)parseWalletDescriptor:(NSString *_Nonnull)content error:(NSError *_Nullable*_Nullable)error;
- (ObjNunchukMatrixEvent *_Nullable)recoverSharedWallet:(NSString *_Nonnull)roomId name:(NSString *_Nonnull)name wallet:(ObjWallet *_Nonnull)wallet error:(NSError *_Nullable*_Nullable)error;
- (BOOL)hasSigner:(ObjSingleSigner *_Nonnull)signer;
- (ObjWallet *_Nullable)parseKeystoneWallet:(NSArray *_Nonnull)data chain:(ChainTypeEnum)chain error:(NSError *_Nullable*_Nullable)error;
- (void)enableLog:(BOOL)isEnabled;
- (ObjTransaction *_Nullable)replaceTransaction:(NSString *_Nonnull)transactionId walletId:(NSString *_Nonnull)walletId newFeeRate:(long)newFeeRate antiFeeSniping:(BOOL)antiFeeSniping error:(NSError *_Nullable*_Nullable)error;
- (ObjDraftTransaction *_Nullable)draftRBFTransactionWithWalletId:(NSString *_Nonnull)walletId transactionId:(NSString *_Nonnull)transactionId outputs:(NSArray<StringIntPair*> *_Nonnull)outputs feeRate:(long)feeRate subtractFeeFromAmount:(BOOL)subtractFeeFromAmount error:(NSError *_Nullable*_Nullable)outError;
- (ObjNunchukMatrixEvent *_Nullable)signAirgapTransactionWithInitEventId:(NSString *_Nonnull)initEventId masterFingerprint:(NSString *_Nonnull)masterFingerprint error:(NSError *_Nullable*_Nullable)error;
- (BOOL)clearPassPhraseWithSignerId:(NSString *_Nonnull)signerId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)setSelectedWallet:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSArray<ObjSingleSigner *>* _Nullable)parseQRSignersWithQRDatas:(NSArray<NSString *>* _Nonnull)qrDatas error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)parseAirgapJsonSignerWithJson:(NSString *_Nonnull)json error:(NSError *_Nullable*_Nullable)error;
- (BOOL)syncAssistedWallet:(ObjAssistedWallet *_Nonnull)wallet error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)syncRemoteTransaction:(ObjRemoteTransaction *_Nonnull)transaction error:(NSError *_Nullable*_Nullable)error;
- (BOOL)updateTransactionScheduleWithWalletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId broadcastTime:(double)broadcastTime error:(NSError *_Nullable*_Nullable)error;

// Tapsigner
- (ObjTapsignerStatus *_Nullable)needSetupWithError:(NSError * _Nullable * _Nullable)outError;
- (NSDictionary *_Nullable)setupTapsignerWithCurrentCVC:(NSString *_Nonnull)currentCVC newCVC:(NSString *_Nonnull)newCVC derivationPath:(NSString *_Nullable)derivationPath chainCode:(NSString *_Nullable)chainCode keyName:(NSString *_Nonnull)keyName error:(NSError * _Nullable * _Nullable)outError;
- (NSNumber *_Nullable)didCreateTapsignerMasterSignerWithError:(NSError * _Nullable * _Nullable)outError;;
- (ObjMasterSigner *_Nullable)createTapsignerMasterSignerWithName:(NSString *_Nonnull)name cvc:(NSString *_Nonnull)cvc replace:(BOOL)replace error:(NSError * _Nullable * _Nullable)outError;
- (ObjTransaction *_Nullable)signTapsignerTransactionWithCVC:(NSString *_Nonnull)cvc walletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError * _Nullable * _Nullable)outError;
- (ObjNunchukMatrixEvent *_Nullable)signTapsignerTransactionWithInitEventId:(NSString *_Nonnull)initEventId cvc:(NSString *_Nonnull)cvc walletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable *_Nullable)error;
- (NSString *_Nullable)signTapsignerTransactionWith:(NSString *_Nonnull)cvc psbt:(NSString *_Nonnull)psbt error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)changeCVC:(NSString *_Nonnull)currentCVC newCVC:(NSString *_Nonnull)newCVC masterSignerId:(NSString *_Nonnull)masterSignerId error:(NSError * _Nullable * _Nullable)outError;
- (NSDictionary *_Nullable)backupTapsignerWithCVC:(NSString *_Nonnull)cvc masterSignerId:(NSString *_Nonnull)masterSignerId error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)healthCheckTapsignerMasterSignerWithCVC:(NSString *_Nonnull)cvc fingerprint:(NSString *_Nonnull)fingerprint message:(NSString *_Nonnull)message path:(NSString *_Nonnull)path signature:(NSString *_Nonnull)signature error:(NSError *_Nullable*_Nullable)error;
- (BOOL)cacheTapsignerMasterSignerXPubWithCVC:(NSString *_Nonnull)cvc masterSignerId:(NSString *_Nonnull)masterSignerId error:(NSError *_Nullable*_Nullable)error;
- (ObjTapsignerStatus *_Nullable)getTapsignerStatusFromMasterSignerFrom:(NSString *_Nonnull)masterSignerId error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)getSignerFromTapsignerMasterSigner:(NSString *_Nonnull)masterSignerId cvc:(NSString *_Nonnull)cvc addressType:(NSString *_Nonnull)addressType walletType:(NSString *_Nonnull)walletType error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)generateRandomChainCode:(NSError * _Nullable * _Nullable)outError;
- (ObjMasterSigner *_Nullable)importTapsignerMasterSigner:(NSString *_Nonnull)filePath key:(NSString *_Nonnull)backupKey error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)cacheDefaultTapsignerMasterSignerXPubWithCVC:(NSString *_Nonnull)cvc masterSignerId:(NSString *_Nonnull)masterSignerId error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)createTapsignerWithName:(NSString *_Nonnull)name cvc:(NSString *_Nonnull)cvc error:(NSError *_Nullable*_Nullable)error;
- (BOOL)verifyTapsignerBackupWithData:(NSString *_Nonnull)backupBase64 password:(NSString *_Nonnull)password keyId:(NSString *_Nonnull)keyId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)verifyColdCardBackupWithData:(NSString *_Nonnull)backupBase64 password:(NSString *_Nonnull)password keyId:(NSString *_Nonnull)keyId error:(NSError *_Nullable*_Nullable)error;

// Satscard
- (ObjTapCardResult *_Nullable)scanNFCCardWithError:(NSError *_Nullable*_Nullable)error;
- (ObjSatscardStatus *_Nullable)getSatscardStatusWithError:(NSError *_Nullable*_Nullable)error;
- (ObjSatscardStatus *_Nullable)setupSatscardWithCurrenctCVC:(NSString *_Nonnull)currentCVC chainCode:(NSString *_Nullable)chainCode error:(NSError *_Nullable*_Nullable)error;
- (ObjSatscardSlot *_Nullable)unsealSatscardWithCurrentCVC:(NSString *_Nonnull)currentCVC slot:(ObjSatscardSlot *_Nonnull)slot error:(NSError * _Nullable * _Nullable)outError;
- (ObjSatscardSlot *_Nullable)fetchSatscardSlotUTXOs:(ObjSatscardSlot *_Nonnull)slot error:(NSError * _Nullable * _Nullable)outError;
- (NSArray<ObjSatscardSlot *>*_Nullable)getSatscardSlotsKeyWithCurrentCVC:(NSString *_Nonnull)currentCVC slots:(NSArray<ObjSatscardSlot *>*_Nonnull)slots error:(NSError * _Nullable * _Nullable)outError;
- (ObjTransaction *_Nullable)sweepSatscardSlot:(ObjSatscardSlot *_Nonnull)slot address:(NSString *_Nonnull)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable * _Nullable)outError;
- (ObjTransaction *_Nullable)SweepSatscardSlots:(NSArray<ObjSatscardSlot*>*_Nonnull)slots address:(NSString *_Nonnull)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable * _Nullable)outError;
- (ObjTransaction *_Nullable)createSatscardSlotsTransactionWithSlots:(NSArray<ObjSatscardSlot*>*_Nonnull)slots address:(NSString *_Nonnull)address feeRate:(NSInteger)feeRate error:(NSError * _Nullable * _Nullable)outError;
- (ObjTransaction *_Nullable)fetchTransactionWithTxId:(NSString *_Nonnull)txId error:(NSError * _Nullable * _Nullable)error;
- (ObjSatscardStatus *_Nullable)unsealAndSetupSatscardWithCurrenctCVC:(NSString *_Nonnull)currentCVC chainCode:(NSString *_Nullable)chainCode slot:(ObjSatscardSlot *_Nonnull)slot error:(NSError *_Nullable*_Nullable)outError;

// ColdCard
- (NSArray *_Nullable)parseJsonSignerWithJson:(NSString *_Nonnull)json error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)createColdCardNFCKey:(NSString *_Nonnull)name xpub:(NSString *_Nonnull)xPub publicKey:(NSString *_Nonnull)publicKey path:(NSString *_Nonnull)path fingerprint:(NSString *_Nonnull)fingerPrint error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getColdCardExportData:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjBSMSData *_Nullable)getPortalBSMSData:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjWallet *_Nullable)parseWalletConfig:(NSString *_Nonnull)config chain:(ChainTypeEnum)chain error:(NSError *_Nullable*_Nullable)error;
- (ObjWallet *_Nullable)createWallet:(ObjWallet *_Nonnull)wallet name:(NSString *_Nonnull)name error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getTransactionPSBT:(NSString *_Nonnull)transactionId walletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)importRawTransaction:(NSString *_Nonnull)walletId rawData:(NSString *_Nonnull)rawData error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)importPSBTWith:(NSString *_Nonnull)walletId base64Pspt:(NSString *_Nonnull)psbt error:(NSError *_Nullable*_Nullable)outError;
- (NSArray *_Nullable)parseJsonWallets:(NSString *_Nonnull)json error:(NSError *_Nullable*_Nullable)error;
- (BOOL)healthCheckColdCard:(ObjSingleSigner *_Nonnull)signer message:(NSString *_Nonnull)message error:(NSError *_Nullable*_Nullable)error;

- (ObjSingleSigner *_Nullable)getDefaultSignerFromMasterSigner:(NSString *_Nonnull)masterSignerId walletType:(NSString *_Nonnull)walletType addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)getSignerFromMasterSigner:(NSString *_Nonnull)masterSignerId path:(NSString *_Nonnull)path error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)getUnusedSignerFromMasterSigner:(NSString *_Nonnull)masterSignerId walletType:(NSString *_Nonnull)walletType addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;

// Premium
- (BOOL)verifyTapsignerBackupWithData:(NSString *_Nonnull)backupBase64 key:(NSString *_Nonnull)backupKey masterSignerId:(NSString *_Nonnull)masterSignerId error:(NSError *_Nullable*_Nullable)error;
- (ObjMasterSigner *_Nullable)importBackupKeyWithData:(NSString *_Nonnull)backupBase64 key:(NSString *_Nonnull)backupKey name:(NSString *_Nonnull)rawName error:(NSError * _Nullable * _Nullable)error;
- (NSString *_Nullable)signHealthCheckMessageWithSingleSigner:(ObjSingleSigner *_Nonnull)singleSigner mesage:(NSString *_Nonnull)message error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)signHealthCheckMessageTapsignerWithSingleSigner:(ObjSingleSigner *_Nonnull)singleSigner mesage:(NSString *_Nonnull)message cvc:(NSString *_Nonnull)cvc error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)getHealthcheckDummyTxWithWallet:(NSString *_Nonnull)walletId body:(NSString *_Nonnull)body error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)decodeDummyTxWithWallet:(NSString *_Nonnull)walletId psbt:(NSString *_Nonnull)psbt error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)signClaimTransaction:(NSString *_Nonnull)masterSignerId psbt:(NSString *_Nonnull)psbt subAmount:(UInt64)subAmount fee:(UInt64)fee feeRate:(UInt64)feeRate error:(NSError *_Nullable*_Nullable)error;
- (BOOL)forceRefreshWalletWithWalletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)decodeDummyTxWithData:(NSData *_Nonnull)data walletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)addKeyTag:(NSString *_Nonnull)tag path:(NSString *_Nonnull)path masterFingerprint:(NSString *_Nonnull)masterFingerprint error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)singleSignerWithName:(NSString *_Nonnull)name xpub:(NSString *_Nonnull)xPub xpubKey:(NSString *_Nonnull)xPubkey path:(NSString *_Nonnull)path fingerprint:(NSString *_Nonnull)fingerPrint error:(NSError *_Nullable*_Nullable)outError;

// Coin
- (NSArray *_Nullable)getCoins:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getInputCoins:(NSString *_Nonnull)walletId transactionId:(NSString *_Nonnull)transactionId error:(NSError *_Nullable*_Nullable)outError;
- (NSArray *_Nullable)getCoinTags:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjCoinTag *_Nullable)createCoinTag:(NSString *_Nonnull)walletId name:(NSString *_Nonnull)name color:(NSString *_Nonnull)color error:(NSError *_Nullable*_Nullable)error;
- (BOOL)updateCoinTag:(NSString *_Nonnull)walletId tag:(ObjCoinTag *_Nonnull)tag error:(NSError *_Nullable*_Nullable)error;
- (BOOL)deleteCoinTag:(NSString *_Nonnull)walletId tagId:(int)tagId error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getCoinCollections:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjCoinCollection *_Nullable)createCoinCollection:(NSString *_Nonnull)walletId name:(NSString *_Nonnull)name error:(NSError *_Nullable*_Nullable)error;
- (BOOL)updateCoinCollection:(NSString *_Nonnull)walletId collection:(ObjCoinCollection *_Nonnull)collection applyToExistingCoins:(BOOL)applyToExistingCoins error:(NSError *_Nullable*_Nullable)error;
- (BOOL)deleteCoinCollection:(NSString *_Nonnull)walletId collectionId:(int)collectionId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)lockCoin:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (BOOL)unlockCoin:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (BOOL)tagCoin:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId tagId:(int)tagId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (BOOL)untagCoin:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId tagId:(int)tagId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (BOOL)addCoinToCollection:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId collectionId:(int)collectionId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (BOOL)removeCoinFromCollection:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId collectionId:(int)collectionId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getCoinsByTag:(NSString *_Nonnull)walletId tagId:(int)tagId error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getCoinsInCollection:(NSString *_Nonnull)walletId collectionId:(int)collectionId error:(NSError *_Nullable*_Nullable)error;
- (NSNumber *_Nullable)importCoinData:(NSString *_Nonnull)walletId data:(NSString *_Nonnull)data forceUpdate:(BOOL)forceUpdate error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)exportCoinData:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)importBIP329:(NSString *_Nonnull)walletId data:(NSString *_Nonnull)data error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getCoinAncestry:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId vout:(int)vout error:(NSError *_Nullable*_Nullable)error;

- (NSString *_Nullable)exportBIP329:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getHealthCheckPath:(NSError *_Nullable*_Nullable)error;
- (ObjSignMessage *_Nullable)signMessage:(NSString *_Nonnull)signerId path:(NSString *_Nonnull)path message:(NSString *_Nonnull)message error:(NSError *_Nullable*_Nullable)error;
- (ObjSignMessage *_Nullable)signMessageTapsignerWithCVC:(NSString *_Nonnull)cvc signerId:(NSString *_Nonnull)signerId path:(NSString *_Nonnull)path message:(NSString *_Nonnull)message error:(NSError *_Nullable*_Nullable)error;
- (BOOL)isAddressOfWallet:(NSString *_Nonnull)walletId address:(NSString *_Nonnull)address;
- (BOOL)addKey:(ObjKeyInfo *_Nonnull)key error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getRawTransaction:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)importDummyTx:(NSString *_Nonnull)data error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)saveDummyTxToken:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId token:(NSString *_Nonnull)token error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)getDummyTxTokens:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable*_Nullable)error;
- (ObjTransaction *_Nullable)getDummyTx:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)deleteDummyTx:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getDummyTxsId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSNumber *_Nullable)getLastUsedSignerIndex:(NSString *_Nonnull)xfp walletType:(NSString *_Nonnull)walletType addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (ObjSingleSigner *_Nullable)getSignerWithIndex:(NSInteger)index xfp:(NSString *_Nonnull)xfp walletType:(NSString *_Nonnull)walletType addressType:(NSString *_Nonnull)addressType error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getBSMSExportData:(NSString *_Nonnull)content error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getWalletExportData:(ObjWallet *_Nonnull)wallet format:(NunchukExportFormat)format error:(NSError *_Nullable*_Nullable)error;
- (ObjWalletData *_Nullable)getBSMSAndFirstAddressWithQRs:(NSArray *_Nonnull)data chain:(ChainTypeEnum)chain error:(NSError *_Nullable*_Nullable)error;
- (ObjWalletData *_Nullable)getBSMSAndFirstAddress:(NSString *_Nonnull)config chain:(ChainTypeEnum)chain error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)parseJsonWalletData:(NSString *_Nonnull)json error:(NSError *_Nullable*_Nullable)error;
- (ObjWalletData *_Nullable)getWalletData:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)customizeTapsignerWithCVC:(NSString *_Nonnull)cvc masterSignerId:(NSString *_Nonnull)masterSignerId path:(NSString *_Nonnull)path error:(NSError *_Nullable*_Nullable)error;

- (ObjTransaction *_Nullable)cancelRBFTransaction:(NSString *_Nonnull)transactionId walletId:(NSString *_Nonnull)walletId newFeeRate:(long)newFeeRate newAddress:(NSString *_Nonnull)newAddress antiFeeSniping:(BOOL)antiFeeSniping error:(NSError *_Nullable*_Nullable)error;
- (ObjDraftTransaction *_Nullable)draftCancelRBFTransactionWithWalletId:(NSString *_Nonnull)walletId transactionId:(NSString *_Nonnull)transactionId newAddress:(NSString *_Nonnull)newAddress newFeeRate:(long)newFeeRate error:(NSError *_Nullable*_Nullable)outError;
- (NSArray *_Nullable)exportBCUR2:(NSString *_Nonnull)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError *_Nullable*_Nullable)outError;
- (NSArray<NSString *>*_Nullable)exportBBQRWalletWithId:(NSString *_Nonnull)walletId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable * _Nullable)outError;
- (NSArray<NSString *>*_Nullable)exportBBQRTransactionWithWalletId:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId fragmentLength:(NSInteger)fragmentLength error:(NSError * _Nullable * _Nullable)outError;
- (ObjSingleSigner *_Nullable)createPortalKeyWithName:(NSString *_Nonnull)name signer:(ObjSingleSigner *_Nonnull)signer error:(NSError *_Nullable*_Nullable)outError;

// Rollover

- (NSNumber *_Nullable)estimateRollOverTransactionCount:(NSString *_Nonnull)walletId tags:(NSArray *_Nonnull)tags collections:(NSArray *_Nonnull)collections error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary *_Nullable)estimateRollOverAmount:(NSString *_Nonnull)sourceWalletId destinationWalletId:(NSString *_Nonnull)destinationWalletId tags:(NSArray *_Nonnull)tags collections:(NSArray *_Nonnull)collections feeRate:(long)feeRate error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)draftRollOverTransactions:(NSString *_Nonnull)sourceWalletId destinationWalletId:(NSString *_Nonnull)destinationWalletId tags:(NSArray *_Nonnull)tags collections:(NSArray *_Nonnull)collections feeRate:(long)feeRate error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)createRollOverTransactions:(NSString *_Nonnull)sourceWalletId destinationWalletId:(NSString *_Nonnull)destinationWalletId tags:(NSArray *_Nonnull)tags collections:(NSArray *_Nonnull)collections feeRate:(long)feeRate antiFeeSniping:(BOOL)antiFeeSniping error:(NSError *_Nullable*_Nullable)error;
- (NSNumber *_Nullable)getAddressIndex:(NSString *_Nonnull)walletId appDisplayAddress:(NSString *_Nonnull)appDisplayAddress error:(NSError *_Nullable*_Nullable)error;

// Value key set

- (NSArray *_Nullable)getKeysetStatus:(NSString *_Nonnull)walletId txId:(NSString *_Nonnull)txId error:(NSError *_Nullable*_Nullable)error;

// Group wallet

- (BOOL)enableGroupWallet:(NSString *_Nonnull)osName
                osVersion:(NSString *_Nonnull)osVersion
               appVersion:(NSString *_Nonnull)appVersion
                 deviceId:(NSString *_Nonnull)deviceId
              deviceClass:(NSString *_Nonnull)deviceClass
                 apiToken:(NSString *_Nonnull)apiToken
                    error:(NSError *_Nullable*_Nullable)error;
- (BOOL)startConsumeGroupEvent:(NSError *_Nullable*_Nullable)error;
- (BOOL)stopConsumeGroupEvent:(NSError *_Nullable*_Nullable)error;
- (BOOL)sendGroupMessage:(NSString *_Nonnull)walletId
                 message:(NSString *_Nonnull)message
                  signer:(ObjSingleSigner *_Nullable)signer
                   error:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getGroupMessages:(NSString *_Nonnull)walletId
                                  page:(int)page
                              pageSize:(int)pageSize
                              isLatest:(BOOL)isLatest
                                 error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupConfig *_Nullable)getGroupConfig:(NSError *_Nullable*_Nullable)error;
- (ObjGroupWalletConfig *_Nullable)getGroupWalletConfig:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)setGroupWalletConfig:(NSString *_Nonnull)walletId config:(ObjGroupWalletConfig *_Nonnull)config error:(NSError *_Nullable*_Nullable)error;
- (void)observeGroupMessage;
- (ObjGroupSandbox *_Nullable)createGroup:(NSString *_Nonnull)name 
                                        m:(int)m 
                                        n:(int)n 
                              addressType:(NSString *_Nonnull)addressType 
                                    error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)getGroup:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (NSNumber *_Nullable)getGroupOnline:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (NSArray<ObjGroupSandbox *> *_Nullable)getGroups:(NSError *_Nullable*_Nullable)error;
- (NSDictionary<NSString*, NSString*> *_Nullable)parseGroupUrl:(NSString *_Nonnull)url error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)joinGroup:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)addSignerToGroup:(NSString *_Nonnull)groupId 
                                        signer:(ObjSingleSigner *_Nonnull)signer 
                                         index:(int)index 
                                         error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)removeSignerFromGroup:(NSString *_Nonnull)groupId index:(int)index error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)updateGroup:(NSString *_Nonnull)groupId 
                                     name:(NSString *_Nonnull)name 
                                        m:(int)m 
                                        n:(int)n 
                              addressType:(NSString *_Nonnull)addressType 
                                error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)finalizeGroup:(NSString *_Nonnull)groupId valueKeyset:(NSArray *_Nonnull)valueKeyset error:(NSError *_Nullable*_Nullable)error;
- (BOOL)deleteGroup:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (void)observeGroupSandbox;
- (void)observeGroupOnline;
- (void)observeGroupDeleted;
- (ObjGroupSandbox *_Nullable)setSlotOccupied:(NSString *_Nonnull)groupId 
                                       index:(int)index 
                                       value:(BOOL)value 
                                       error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)getGroupDeviceUID:(NSError *_Nullable*_Nullable)error;
- (NSArray *_Nullable)getGroupWallets:(NSError *_Nullable*_Nullable)error;
- (NSArray<NSString *> *_Nullable)getDeprecatedGroupWallets:(NSError *_Nullable*_Nullable)error;
- (int)getUnreadMessagesCount:(NSString *_Nonnull)walletId;
- (BOOL)setLastReadMessage:(NSString *_Nonnull)walletId messageId:(NSString *_Nonnull)messageId error:(NSError *_Nullable*_Nullable)error;
- (ObjWallet *_Nullable)isGroupWalletExisted:(NSString *_Nonnull)content error:(NSError *_Nullable*_Nullable)error;
- (BOOL)recoverGroupWallet:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)decryptGroupWalletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (NSString *_Nullable)decryptGroupTxId:(NSString *_Nonnull)txId walletId:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;

// Replace Group Wallet
- (ObjGroupSandbox *_Nullable)createReplaceGroup:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;
- (ObjGroupSandbox *_Nullable)acceptReplaceGroup:(NSString *_Nonnull)walletId groupId:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (BOOL)declineReplaceGroup:(NSString *_Nonnull)walletId groupId:(NSString *_Nonnull)groupId error:(NSError *_Nullable*_Nullable)error;
- (NSDictionary<NSString*, NSNumber*> *_Nullable)getReplaceGroups:(NSString *_Nonnull)walletId error:(NSError *_Nullable*_Nullable)error;

// Add listener for replacement requests
- (void)observeReplaceRequest;

- (BOOL)exportTransactionHistoryWithWalletId:(NSString *_Nonnull)walletId filePath:(NSString *_Nonnull)filePath format:(NunchukExportFormat)format error:(NSError *_Nullable*_Nullable)error;

- (NSNumber *_Nullable)getScriptPathFeeRateWithWalletId:(NSString *_Nonnull)walletId transaction:(ObjTransaction *_Nonnull)transaction error:(NSError *_Nullable*_Nullable)error;

@end
#endif
