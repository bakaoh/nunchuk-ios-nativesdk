//
//  ObjDevice.h
//  example-ios
//
//  Created by congtung private on 02/03/2021.
//
#import <Foundation/Foundation.h>
#ifndef ObjDevice_h
#define ObjDevice_h

@interface ObjDevice : NSObject
@property(nonatomic, strong, nullable) NSString* type;
@property(nonatomic, strong, nullable) NSString* path;
@property(nonatomic, strong, nullable) NSString* model;
@property(nonatomic, strong, nullable) NSString* masterFingerPrint;
@property(nonatomic) bool isConnected;
@property(nonatomic) bool needsPassPhraseSent;
@property(nonatomic) bool needsPinSent;
@property(nonatomic) bool initialized;
@property(nonatomic, assign) BOOL isTapsigner;
@end
#endif /* ObjDevice_h */
