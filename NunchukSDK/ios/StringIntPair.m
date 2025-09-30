//
//  StringIntPair.m
//  nunchukSDK
//
//  Created by congtung private on 13/05/2021.
//

#import <Foundation/Foundation.h>
#import "StringIntPair.h"

@implementation StringIntPair

@end

@implementation IntPair

- (instancetype _Nullable)initWithFirst:(int)first second:(int)second {
    IntPair *obj = [IntPair new];
    obj.first = first;
    obj.second = second;
    return obj;
}

@end

