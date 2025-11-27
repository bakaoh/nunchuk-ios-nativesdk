//
//  Header.h
//  nunchukWalletSDK
//
//  Created by congtung private on 13/05/2021.
//

#ifndef ObjTransaction_h
#define ObjTransaction_h
#include "StringIntPair.h"
#import "ObjSingleSigner.h"

@interface ObjTransactionInput : NSObject

@property(nonatomic, strong, nonnull) NSString *txId;
@property(nonatomic, assign) int64_t vout;
@property(nonatomic, assign) int64_t nSequence;

- (instancetype _Nullable)initWithTxId:(NSString *_Nonnull)txId vout:(int64_t)vout nSequence:(int64_t)nSequence;

@end

typedef StringIntPair ObjOutput;  // address-amount pair

@interface ObjTransaction : NSObject
@property(nonatomic, strong, nonnull) NSString* transactionId;
@property(nonatomic) int height;
@property(nonatomic) NSArray<ObjTransactionInput *> * _Nullable input;
@property(nonatomic) NSArray<ObjOutput*> * _Nullable output;
@property(nonatomic) NSArray<ObjOutput*> * _Nullable  userOutput;
@property(nonatomic) NSArray<ObjOutput*> * _Nullable receivedOutput;
@property(nonatomic, strong, nonnull) NSArray * signers;
@property(nonatomic, strong, nonnull) NSString* status;
@property(nonatomic, strong, nonnull) NSString* replacedId;
@property(nonatomic) int64_t fee;
@property(nonatomic) int64_t feeRate;
@property(nonatomic) int64_t blockTime;
@property(nonatomic) bool subtractFeeFromAmount;
@property(nonatomic) bool isReceived;
@property(nonatomic) int64_t subAmount;
@property(nonatomic) int changeIndex;
@property(nonatomic, strong, nonnull) NSString * memo;
@property(nonatomic) int m;
@property(nonatomic, strong, nullable) NSString *replaceTXid;
@property(nonatomic, strong, nonnull) NSString *psbt;
@property(nonatomic) int64_t scheduleTime;
@property(nonatomic) int vsize;
@property(nonatomic) NSArray<ObjSingleSigner *> *_Nullable signedKeys;

@end

#endif /* Header_h */
