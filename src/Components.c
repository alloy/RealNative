#import "Components.h"
#import "Utils.h"
#import "ReactNative.h"

#import <AudioToolbox/AudioToolbox.h>

static SystemSoundID AirhornSoundID = 0;

#pragma mark -
#pragma mark Components

/**
 * ```js
 * () => {
 *   AudioServicesPlaySystemSound(AirhornSoundID);
 *   console.log("Pew Pew Peeeeeew");
 * }
 * ```
 */
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

/**
 * ```js
 * () => {
 *   const RNButtonComponent = require("react-native").Button;
 *   const props = {
 *     title: "Pew Pew Peeeeeew",
 *     onPress: DJAirhornButtonOnPressHandler,
 *   };
 *   return React.createElement(RNButtonComponent, props);
 * }
 * ```
 */
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

/**
 * ```js
 * (props) => {
 *   const RNViewComponent = require("react-native").View;
 *   const children = props.children;
 *   const containerStyle = {
 *     flex: 1,
 *     backgroundColor: "#f60",
 *     justifyContent: "center",
 *     alignItems: "center",
 *   };
 *   const containerProps = {
 *     style: containerStyle,
 *   };
 *   return React.createElement(RNViewComponent, containerProps, children);
 * }
 * ```
 */
static JSValueRef
ContainerComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef RNViewComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule(ctx), "View");

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

  JSValueRef element = ReactCreateElement(ctx, RNViewComponent, containerProps, children);
  return element;
}

/**
 * ```js
 * (props) => {
 *   const buttonProps = {
 *     key: "epic-button",
 *   };
 *   const buttonElement = React.createElement(DJAirhornButtonComponent, buttonProps);
 *   const containerProps = {
 *     style: containerStyle,
 *   };
 *   const containerElement = React.createElement(ContainerComponent, null, [buttonElement]);
 *   console.log(containerElement);
 *   return containerElement;
 * }
 * ```
 */
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
  JSObjectRef DJAirhornButtonComponent = (JSObjectRef)ObjectGet(ctx, globalObject, "DJAirhornButtonComponent");
  JSObjectRef ContainerComponent = (JSObjectRef)ObjectGet(ctx, globalObject, "ContainerComponent");

  JSObjectRef buttonProps = JSObjectMake(ctx, NULL, NULL);
  ObjectSetString(ctx, buttonProps, "key", "epic-button");
  JSValueRef buttonElement = ReactCreateElement(ctx, DJAirhornButtonComponent, buttonProps, NULL);

  JSObjectRef children = JSObjectMakeArray(ctx, 1, &buttonElement, NULL);
  JSValueRef containerElement = ReactCreateElement(ctx, ContainerComponent, NULL, children);

  // Get your console.log debugging on!
  ConsoleLog(ctx, containerElement);

  return containerElement;
}

#pragma mark -
#pragma mark Initialize

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
