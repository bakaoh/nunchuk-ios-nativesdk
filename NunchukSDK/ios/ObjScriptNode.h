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
    SCRIPT_NODE_UNKNOWN = 0,
    SCRIPT_NODE_PK,
    SCRIPT_NODE_MULTI,
    SCRIPT_NODE_AND,
    SCRIPT_NODE_OR,
    SCRIPT_NODE_THRESH,
    SCRIPT_NODE_TIMEBASED
};

@interface ObjScriptNode : NSObject

@property (nonatomic, strong) NSArray<NSString *> *id;
@property (nonatomic, assign) ScriptNodeType type;
@property (nonatomic, strong) NSArray<ObjScriptNode *> *subs;
@property (nonatomic, strong) NSArray<NSString *> *keys;
@property (nonatomic, assign) int threshold;
@property (nonatomic, assign) int lockTime;

#pragma mark - Utility Methods

+ (NSString *)typeToString:(ScriptNodeType)type;
- (ScriptNodeType)getType;
- (NSArray<NSString *> *)getId;
- (NSArray<ObjScriptNode *> *)getSubs;
- (NSArray<NSString *> *)getKeys;
- (int)getThreshold;
- (int)getLockTime;

@end

#endif /* ObjScriptNode_h */
