#import "Components.h"
#import <AudioToolbox/AudioToolbox.h>

static JSValueRef
ObjectGet(JSContextRef ctx, JSObjectRef obj, char *key) {
  JSStringRef keyName = JSStringCreateWithUTF8CString(key);
  JSValueRef result = JSObjectGetProperty(ctx, obj, keyName, NULL);
  JSStringRelease(keyName);
  return result;
}

static void
ObjectSetValue(JSContextRef ctx, JSObjectRef obj, char *key, JSValueRef value) {
  JSStringRef k = JSStringCreateWithUTF8CString(key);
  JSObjectSetProperty(ctx, obj, k, value, kJSPropertyAttributeNone, NULL);
  JSStringRelease(k);
}

static void
ObjectSetString(JSContextRef ctx, JSObjectRef obj, char *key, char *value) {
  JSStringRef v = JSStringCreateWithUTF8CString(value);
  ObjectSetValue(ctx, obj, key, JSValueMakeString(ctx, v));
  JSStringRelease(v);
}

static void
ObjectSetNumber(JSContextRef ctx, JSObjectRef obj, char *key, double value) {
  ObjectSetValue(ctx, obj, key, JSValueMakeNumber(ctx, value));
}

static void
ConsoleLog(JSContextRef ctx, JSValueRef value) {
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSObjectRef consoleObject = (JSObjectRef)ObjectGet(ctx, globalObject, "console");
  JSObjectRef logFunction = (JSObjectRef)ObjectGet(ctx, consoleObject, "log");
  JSObjectCallAsFunction(ctx, logFunction, NULL, 1, &value, NULL);
}

static JSValueRef
Require(JSContextRef ctx, char *moduleId) {
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

static JSValueRef
ReactCreateElement(
  JSContextRef ctx,
  JSObjectRef component,
  JSObjectRef props,
  JSValueRef children
) {
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

static JSObjectRef
ReactNativeModule(JSContextRef ctx) {
  return (JSObjectRef)Require(ctx, "node_modules/react-native/index.js");
}

static void
DefineComponent(
  JSContextRef ctx,
  char *componentName,
  JSObjectCallAsFunctionCallback componentImplementation
) {
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSStringRef jsComponentName = JSStringCreateWithUTF8CString(componentName);
  JSObjectRef component = JSObjectMakeFunctionWithCallback(ctx, jsComponentName, componentImplementation);
  JSStringRelease(jsComponentName);
  ObjectSetValue(ctx, globalObject, componentName, component);
}

#pragma mark -
#pragma mark Initialize

static SystemSoundID AirhornSoundID = 0;

#pragma mark -
#pragma mark Components

static JSValueRef
DJAirhornButtonOnPressHandler(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  AudioServicesPlaySystemSound(AirhornSoundID);

  JSStringRef message = JSStringCreateWithUTF8CString("Pew Pew Peeeeeew");
  ConsoleLog(ctx, JSValueMakeString(ctx, message));
  JSStringRelease(message);

  return JSValueMakeUndefined(ctx);
}

static JSValueRef
DJAirhornButtonComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef RNButtonComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule(ctx), "Button");

  JSObjectRef props = JSObjectMake(ctx, NULL, NULL);
  ObjectSetString(ctx, props, "title", "Pew Pew Peeeeeew");
  ObjectSetValue(ctx, props, "onPress", JSObjectMakeFunctionWithCallback(ctx, NULL, &DJAirhornButtonOnPressHandler));

  JSValueRef element = ReactCreateElement(ctx, RNButtonComponent, props, NULL);
  return element;
}

static JSValueRef
ContainerComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef ViewComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule(ctx), "View");

  JSObjectRef props = (JSObjectRef)arguments[0];
  JSObjectRef children = (JSObjectRef)ObjectGet(ctx, props, "children");

  /**
   * Putting the C back in CSS
   */
  JSObjectRef containerStyle = JSObjectMake(ctx, NULL, NULL);
  ObjectSetNumber(ctx, containerStyle, "flex", 1);
  ObjectSetString(ctx, containerStyle, "backgroundColor", "#f60");
  ObjectSetString(ctx, containerStyle, "justifyContent", "center");
  ObjectSetString(ctx, containerStyle, "alignItems", "center");

  JSObjectRef containerProps = JSObjectMake(ctx, NULL, NULL);
  ObjectSetValue(ctx, containerProps, "style", containerStyle);

  JSValueRef element = ReactCreateElement(ctx, ViewComponent, containerProps, children);
  return element;
}

static JSValueRef
AppComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSObjectRef ButtonComponent = (JSObjectRef)ObjectGet(ctx, globalObject, "DJAirhornButtonComponent");
  JSObjectRef ContainerComponent = (JSObjectRef)ObjectGet(ctx, globalObject, "ContainerComponent");

  JSObjectRef buttonProps = JSObjectMake(ctx, NULL, NULL);
  ObjectSetString(ctx, buttonProps, "key", "epic-button");
  JSValueRef buttonElement = ReactCreateElement(ctx, ButtonComponent, buttonProps, NULL);

  JSObjectRef children = JSObjectMakeArray(ctx, 1, &buttonElement, NULL);
  JSValueRef containerElement = ReactCreateElement(ctx, ContainerComponent, NULL, children);

  // Get your console.log debugging on!
  ConsoleLog(ctx, containerElement);

  return containerElement;
}

void DefineComponents(JSContextRef ctx)
{
  if (AirhornSoundID == 0) {
    CFURLRef airhornSampleURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("dj-airhorn-sound-effect"), CFSTR("mp3"), NULL);
    AudioServicesCreateSystemSoundID(airhornSampleURL, &AirhornSoundID);
    CFRelease(airhornSampleURL);
  }

  DefineComponent(ctx, "DJAirhornButtonComponent", &DJAirhornButtonComponent);
  DefineComponent(ctx, "ContainerComponent", &ContainerComponent);
  DefineComponent(ctx, "AppComponent", &AppComponent);
}
