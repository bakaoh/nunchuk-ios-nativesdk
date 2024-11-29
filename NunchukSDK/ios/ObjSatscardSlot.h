//
//  ObjSatscardSlot.h
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 31/07/2022.
//

#import <Foundation/Foundation.h>
#import "ObjUnspentOutput.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    UNUSED,
    SEALED,
    UNSEALED,
} ObjSatscardSlotStatus;

@interface ObjSatscardSlot : NSObject
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) ObjSatscardSlotStatus status;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) UInt64 balance;
@property (nonatomic, assign) BOOL isConfirmed;
@property (nonatomic, strong) NSArray<ObjUnspentOutput*> *utxos;
@property (nonatomic, strong) NSData *privateKey;
@property (nonatomic, strong) NSData *publicKey;
@property (nonatomic, strong) NSData *chainCode;
@property (nonatomic, strong) NSData *masterPrivateKey;
@end
NS_ASSUME_NONNULL_END
