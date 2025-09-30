//
//  StringIntPair.h
//  nunchukWalletSDK
//
//  Created by congtung private on 13/05/2021.
//

#ifndef StringIntPair_h
#define StringIntPair_h
@interface StringIntPair: NSObject
@property (nonatomic, strong) NSString* key;
@property (nonatomic) long value;
@end
#endif /* StringIntPair_h */

@interface IntPair: NSObject
@property (nonatomic, assign) int first;
@property (nonatomic, assign) int second;

- (instancetype _Nullable)initWithFirst:(int)first second:(int)second;

@end
