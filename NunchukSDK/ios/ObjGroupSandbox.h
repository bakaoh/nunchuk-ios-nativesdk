//
//  ObjGroupSandbox.h
//  example-ios
//
//

#import "ObjSingleSigner.h"

@interface ObjGroupSandbox : NSObject

@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *walletId;
@property (nonatomic, strong) NSString *replaceWalletId;
@property (nonatomic, strong) NSString *pubkey;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) int m;
@property (nonatomic, assign) int n;
@property (nonatomic, strong) NSString *addressType;
@property (nonatomic, strong) NSString *walletType;
@property (nonatomic, strong, nullable) NSString *miniscriptTemplate;
@property (nonatomic, strong) NSMutableArray<ObjSingleSigner *> *signers;
@property (nonatomic, strong) NSArray<NSString *> *ephemeralKeys;
@property (nonatomic, assign) BOOL isFinalized;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSArray *> *occupiedSlots; // [index: [timestamp, deviceUID]]
@property (nonatomic, strong) NSDictionary<NSString *, ObjSingleSigner *> *namedSigners; // [name: ObjSingleSigner]
@property (nonatomic, strong) NSDictionary<NSString *, NSArray *> *namedOccupied; // [name: [timestamp, deviceUID]]

@end

