#import "AppDelegate.h"

#import <JavaScriptCore/JavaScriptCore.h>
#import <AudioToolbox/AudioToolbox.h>

#import <React/RCTBridge.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#if DEBUG
#import <FlipperKit/FlipperClient.h>
#import <FlipperKitLayoutPlugin/FlipperKitLayoutPlugin.h>
#import <FlipperKitUserDefaultsPlugin/FKUserDefaultsPlugin.h>
#import <FlipperKitNetworkPlugin/FlipperKitNetworkPlugin.h>
#import <SKIOSNetworkPlugin/SKIOSNetworkAdapter.h>
#import <FlipperKitReactPlugin/FlipperKitReactPlugin.h>

static void InitializeFlipper(UIApplication *application) {
  FlipperClient *client = [FlipperClient sharedClient];
  SKDescriptorMapper *layoutDescriptorMapper = [[SKDescriptorMapper alloc] initWithDefaults];
  [client addPlugin:[[FlipperKitLayoutPlugin alloc] initWithRootNode:application withDescriptorMapper:layoutDescriptorMapper]];
  [client addPlugin:[[FKUserDefaultsPlugin alloc] initWithSuiteName:nil]];
  [client addPlugin:[FlipperKitReactPlugin new]];
  [client addPlugin:[[FlipperKitNetworkPlugin alloc] initWithNetworkAdapter:[SKIOSNetworkAdapter new]]];
  [client start];
}
#endif

@interface RCTCxxBridge (Private)
- (void)realNative_foo;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
  InitializeFlipper(application);
#endif

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"RealNative"
                                            initialProperties:nil];

  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

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
  JSObjectRef requireFunction = (JSObjectRef)ObjectGet(ctx, globalObject, "__r");

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

- (void)bridgeDidInitializeJSGlobalContext:(void *)contextRef;
{
  JSGlobalContextRef ctx = contextRef;

  if (AirhornSoundID == 0) {
    CFURLRef airhornSampleURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("dj-airhorn-sound-effect"), CFSTR("mp3"), NULL);
    AudioServicesCreateSystemSoundID(airhornSampleURL, &AirhornSoundID);
    CFRelease(airhornSampleURL);
  }

  DefineComponent(ctx, "DJAirhornButtonComponent", &DJAirhornButtonComponent);
  DefineComponent(ctx, "ContainerComponent", &ContainerComponent);
  DefineComponent(ctx, "AppComponent", &AppComponent);
}

#pragma mark -
#pragma mark Components

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

  JSValueRef buttonElement = ReactCreateElement(ctx, ButtonComponent, NULL, NULL);

  JSObjectRef children = JSObjectMakeArray(ctx, 1, &buttonElement, NULL);
  JSValueRef containerElement = ReactCreateElement(ctx, ContainerComponent, NULL, children);

  // Get your console.log debugging on!
  ConsoleLog(ctx, containerElement);

  return containerElement;
}

@end
