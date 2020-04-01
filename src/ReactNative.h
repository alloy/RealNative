#import <JavaScriptCore/JavaScriptCore.h>

void ConsoleLog(JSContextRef ctx, JSValueRef value);

JSValueRef Require(JSContextRef ctx, char *moduleId);

JSObjectRef ReactNativeModule(JSContextRef ctx);

// Technically from the `react` package, not `react-native` ¯\_(ツ)_/¯
JSValueRef ReactCreateElement(JSContextRef ctx, JSObjectRef component, JSObjectRef props, JSValueRef children);
