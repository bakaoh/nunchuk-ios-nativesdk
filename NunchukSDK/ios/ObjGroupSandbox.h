//
//  ObjGroupSandbox.h
//  example-ios
//
//

#import "ObjSingleSigner.h"

@interface ObjGroupSandbox : NSObject

@property (nonatomic, strong, nonnull) NSString *groupId;
@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nullable) NSString *walletId;
@property (nonatomic, strong, nullable) NSString *replaceWalletId;
@property (nonatomic, strong, nullable) NSString *pubkey;
@property (nonatomic, strong, nonnull) NSString *url;
@property (nonatomic, assign) int m;
@property (nonatomic, assign) int n;
@property (nonatomic, strong, nonnull) NSString *addressType;
@property (nonatomic, strong, nonnull) NSString *walletType;
@property (nonatomic, strong, nullable) NSString *miniscriptTemplate;
@property (nonatomic, strong, nullable) NSMutableArray<ObjSingleSigner *> *signers;
@property (nonatomic, strong, nullable) NSArray<NSString *> *ephemeralKeys;
@property (nonatomic, assign) BOOL isFinalized;
@property (nonatomic, strong, nullable) NSDictionary<NSNumber *, NSArray *> *occupiedSlots; // [index: [timestamp, deviceUID]]
@property (nonatomic, strong, nullable) NSDictionary<NSString *, ObjSingleSigner *> *namedSigners; // [name: ObjSingleSigner]
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSArray *> *namedOccupiedSlots; // [name: [timestamp, deviceUID]]

@end

