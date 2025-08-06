//
//  ObjTimeLock.h
//  nunchukSDK
//
//  Created by macbook on 11/1/25.
//

typedef enum {
    NONE = 0,
    TIME_LOCK = 1,
    HEIGHT_LOCK = 2,
} TimeLockBased;

@interface ObjTimeLock : NSObject

@property (nonatomic, assign) int based;
@property (nonatomic, assign) int type;
@property (nonatomic, assign) long long value;
@property (nonatomic, assign) long long k;

@end 
