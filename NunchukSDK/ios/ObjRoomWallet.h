//
//  ObjRoomWallet.h
//  nunchukWalletSDK
//
//  Created by Ha Nguyen Duc on 2021/08/30.
//

#ifndef ObjRoomWallet_h
#define ObjRoomWallet_h
typedef enum RoomWalletState {
    PENDING,
    FINALIZE,
    CANCEL
} RoomWalletState;
@interface ObjRoomWallet: NSObject
@property (strong, nonatomic, nullable) NSString *walletId;
@property (strong, nonatomic, nullable) NSString *initializeEventId;
@property (strong, nonatomic, nullable) NSArray *joinEventIds;
@property (strong, nonatomic, nullable) NSArray *leaveEventIds;
@property (strong, nonatomic, nullable) NSString *finalizeEventId;
@property (strong, nonatomic, nullable) NSString *cancelEventId;
@property (strong, nonatomic, nullable) NSString *readyEventId;
@property (strong, nonatomic, nullable) NSString *deleteEventId;
@property (strong, nonatomic, nullable) NSString *jsonContent;
@property (strong, nonatomic, nullable) NSString *roomId;
@property (assign, nonatomic) RoomWalletState state;
@end

#endif /* ObjRoomWallet_h */
