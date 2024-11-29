//
//  ObjBtcUri.h
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 09/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjBtcUri : NSObject
@property(nonatomic, strong, nonnull) NSString *address;
@property(nonatomic, assign) NSInteger amount;
@property(nonatomic, strong, nullable) NSString *label;
@property(nonatomic, strong, nullable) NSString *message;
@property(nonatomic, strong, nullable) NSDictionary<NSString*, NSString*> *others;
@end

NS_ASSUME_NONNULL_END
