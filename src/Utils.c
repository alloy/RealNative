#import "Utils.h"

JSValueRef ObjectGet(JSContextRef ctx, JSObjectRef obj, char *key)
{
  JSStringRef keyName = JSStringCreateWithUTF8CString(key);
  JSValueRef result = JSObjectGetProperty(ctx, obj, keyName, NULL);
  JSStringRelease(keyName);
  return result;
}

void ObjectSetValue(JSContextRef ctx, JSObjectRef obj, char *key, JSValueRef value)
{
  JSStringRef k = JSStringCreateWithUTF8CString(key);
  JSObjectSetProperty(ctx, obj, k, value, kJSPropertyAttributeNone, NULL);
  JSStringRelease(k);
}

void ObjectSetString(JSContextRef ctx, JSObjectRef obj, char *key, char *value)
{
  JSStringRef v = JSStringCreateWithUTF8CString(value);
  ObjectSetValue(ctx, obj, key, JSValueMakeString(ctx, v));
  JSStringRelease(v);
}

void ObjectSetNumber(JSContextRef ctx, JSObjectRef obj, char *key, double value)
{
  ObjectSetValue(ctx, obj, key, JSValueMakeNumber(ctx, value));
}
