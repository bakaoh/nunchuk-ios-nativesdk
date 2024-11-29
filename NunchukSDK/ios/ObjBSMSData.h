//
//  ObjBSMSData.h
//  nunchukWalletSDK
//
//  Created by HungNguyen on 2024/07/22.
//

@interface ObjBSMSData : NSObject
@property(nonatomic, strong, nullable) NSString* version;
@property(nonatomic, strong, nullable) NSString* descriptor;
@property(nonatomic, strong, nullable) NSString* pathRestriction;
@property(nonatomic, strong, nullable) NSString* firstAddress;
@end
