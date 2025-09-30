//
//  ObjSingleSigner.h
//  example-ios
//
//  Created by congtung private on 02/03/2021.
//

#ifndef ObjSingleSigner_h
#define ObjSingleSigner_h
#import "StringIntPair.h"
#import "ObjMasterSigner.h"

@interface ObjSingleSigner : NSObject
@property(nonatomic, strong, nonnull) NSString* signerId;
@property(nonatomic, strong, nullable) NSString* signerName;
@property(nonatomic, strong, nullable) NSString* xpub;
@property(nonatomic, strong, nullable) NSString* bip32Path;
@property(nonatomic, strong, nullable) NSString* messageToSign;
@property(nonatomic, strong, nullable) NSString* publicKey;
@property(nonatomic, strong, nullable) NSString* masterFingerPrint;
@property(nonatomic, strong, nullable) NSString* descriptor;
@property(nonatomic, assign) double lastHealthCheckTS;
@property(nonatomic, assign) BOOL hasMasterSigner;
@property(nonatomic, assign) ObjCSignerType type;
@property(nonatomic, strong, nonnull) NSArray *tags;
@property(nonatomic, assign) BOOL isVisible;
@property(nonatomic, assign) NSInteger indexPath;
@property(nonatomic, strong, nullable) IntPair *externalInternalIndex;

- (instancetype _Nonnull )initWithName:(NSString * _Nonnull)name
                                  xpub:(NSString * _Nonnull)xpub
                             bip32Path:(NSString * _Nonnull)bip32Path
                         messageToSign:(NSString * _Nonnull)messageToSign
                             publicKey:(NSString * _Nonnull)publicKey
                     masterFingerPrint:(NSString * _Nonnull)masterFingerPrint
                              signerId:(NSString * _Nonnull)signerId
                            descriptor:(NSString * _Nonnull)descriptor
                     lastHealthCheckTS:(double)lastHealthCheckTS
                                  type:(ObjCSignerType)type
                       hasMasterSigner:(BOOL)hasMasterSigner
                                  tags:(NSArray *_Nonnull)tags
                             isVisible:(BOOL)isVisible
                             indexPath:(NSInteger)indexPath
                 externalInternalIndex:(IntPair * _Nullable)externalInternalIndex;

- (BOOL)hasAirgapTypeTag;

@end
#endif /* ObjRemoteSigner_h */
