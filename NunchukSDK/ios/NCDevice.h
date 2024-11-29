//
//  NCDevice.h
//  nunchukSDK
//
//  Created by TungImac on 26/02/2021.
//

#ifndef NCDevice_h
#define NCDevice_h
@interface NCDevice: NSObject

@property(nonatomic, strong, nullable) NSString* fingerPrint;
@property(nonatomic, strong, nullable) NSString* type;
@property(nonatomic, strong, nullable) NSString* model;
@property(nonatomic, strong, nullable) Bool connected;

@end

#endif /* NCDevice_h */
