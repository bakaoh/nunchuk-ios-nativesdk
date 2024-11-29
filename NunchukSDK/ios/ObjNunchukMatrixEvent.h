//
//  ObjSignerLibrary.h
//  example-ios
//
//  Created by congtung private on 26/03/2021.
//

#ifndef ObjNunchukMatrixEvent_h
#define ObjNunchukMatrixEvent_h
@interface ObjNunchukMatrixEvent : NSObject
@property(nonatomic, strong, nonnull) NSString* type;
@property(nonatomic, strong, nonnull) NSString* content;
@property(nonatomic, strong, nonnull) NSString* eventId;
@property(nonatomic, strong, nonnull) NSString* roomId;
@property(nonatomic, strong, nonnull) NSString* senderId;
@property(nonatomic, assign) int64_t timestamp;
@end
#endif /* ObjWalletLibrary_h */
