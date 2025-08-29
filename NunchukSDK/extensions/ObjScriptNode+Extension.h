//
//  ObjScriptNode+Extension.h
//  nunchukSDK
//
//  Created on 5/13/2025.
//

#ifndef ObjScriptNode_Extension_h
#define ObjScriptNode_Extension_h

#include <nunchuk.h>

using namespace nunchuk;

@interface ObjScriptNode (Extension)

/**
 * Initializes an ObjScriptNode from a C++ ScriptNode by reference.
 * This method safely extracts data from the ScriptNode without triggering the deleted copy constructor.
 *
 * @param node A const reference to a C++ ScriptNode
 * @return An initialized ObjScriptNode instance
 */
- (instancetype _Nullable)initWithScriptNode:(const ScriptNode &)node;

@end

#endif /* ObjScriptNode_Extension_h */ 
