#import "ReactNative.h"
#import "Utils.h"

void ConsoleLog(JSContextRef ctx, JSValueRef value)
{
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSObjectRef consoleObject = (JSObjectRef)ObjectGet(ctx, globalObject, "console");
  JSObjectRef logFunction = (JSObjectRef)ObjectGet(ctx, consoleObject, "log");
  JSObjectCallAsFunction(ctx, logFunction, NULL, 1, &value, NULL);
}

JSValueRef Require(JSContextRef ctx, char *moduleId)
{
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);

  // This is Metro’s `require` function:
  // https://github.com/facebook/metro/blob/e8fecfea/packages/metro/src/lib/polyfills/require.js#L65
  JSObjectRef requireFunction = (JSObjectRef)ObjectGet(ctx, globalObject, "__r");\

  JSStringRef moduleIdName = JSStringCreateWithUTF8CString(moduleId);
  JSValueRef moduleIdNameValue = JSValueMakeString(ctx, moduleIdName);
  JSValueRef error = NULL;
  JSValueRef result = JSObjectCallAsFunction(ctx, requireFunction, NULL, 1, &moduleIdNameValue, &error);
  JSStringRelease(moduleIdName);

  if (error) {
    ConsoleLog(ctx, error);
    return NULL;
  } else {
    return result;
  }
}

JSValueRef ReactCreateElement(JSContextRef ctx, JSObjectRef component, JSObjectRef props, JSValueRef children)
{
  JSObjectRef ReactModule = (JSObjectRef)Require(ctx, "node_modules/react/index.js");
  JSObjectRef createElement = (JSObjectRef)ObjectGet(ctx, ReactModule, "createElement");

  if (children == NULL) {
    children = JSObjectMakeArray(ctx, 0, NULL, NULL);
  }
  if (props == NULL) {
    props = JSObjectMake(ctx, NULL, NULL);
  }

  JSValueRef args[3] = { component, props, children };
  JSValueRef element = JSObjectCallAsFunction(ctx, createElement, NULL, 3, args, NULL);
  return element;
}

JSObjectRef ReactNativeModule(JSContextRef ctx)
{
  return (JSObjectRef)Require(ctx, "node_modules/react-native/index.js");
}
