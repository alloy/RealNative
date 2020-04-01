/**
 * Any self respecting JS app has got to have a ‘utils’ file.
 */

#import <JavaScriptCore/JavaScriptCore.h>

JSValueRef ObjectGet(JSContextRef ctx, JSObjectRef obj, char *key);

void ObjectSetValue(JSContextRef ctx, JSObjectRef obj, char *key, JSValueRef value);

void ObjectSetString(JSContextRef ctx, JSObjectRef obj, char *key, char *value);

void ObjectSetNumber(JSContextRef ctx, JSObjectRef obj, char *key, double value);
