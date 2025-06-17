//
//  ObjScriptNode.h
//  nunchukSDK
//
//  Created on 10/3/2023.
//

#ifndef ObjScriptNode_h
#define ObjScriptNode_h

#import <Foundation/Foundation.h>

@class ObjScriptNode;

typedef NS_ENUM(NSInteger, ScriptNodeType) {
    SCRIPT_NODE_NONE = 0,
    SCRIPT_NODE_PK,
    SCRIPT_NODE_OLDER,
    SCRIPT_NODE_AFTER,
    SCRIPT_NODE_HASH160,
    SCRIPT_NODE_HASH256,
    SCRIPT_NODE_RIPEMD160,
    SCRIPT_NODE_SHA256,
    SCRIPT_NODE_AND,
    SCRIPT_NODE_OR,
    SCRIPT_NODE_ANDOR,
    SCRIPT_NODE_THRESH,
    SCRIPT_NODE_MULTI,
    SCRIPT_NODE_OR_TAPROOT
};

@interface ObjScriptNode : NSObject

@property (nonatomic, strong) NSArray<NSString *> *id;
@property (nonatomic, assign) ScriptNodeType type;
@property (nonatomic, strong) NSArray<ObjScriptNode *> *subs;
@property (nonatomic, strong) NSArray<NSString *> *keys;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) uint32_t k;  // Corresponds to k_ in C++
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *signers;  // Additional mapping for signers

#pragma mark - Utility Methods

+ (NSString *)typeToString:(ScriptNodeType)type;
- (ScriptNodeType)getType;
- (NSArray<NSString *> *)getId;
- (NSArray<ObjScriptNode *> *)getSubs;
- (NSArray<NSString *> *)getKeys;
- (NSData *)getData;
- (uint32_t)getK;

@end

#endif /* ObjScriptNode_h */
