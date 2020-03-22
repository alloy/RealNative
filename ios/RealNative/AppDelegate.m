#import "AppDelegate.h"

#import <JavaScriptCore/JavaScriptCore.h>

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
NativeAppComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef ReactNativeModule = (JSObjectRef)Require(ctx, "node_modules/react-native/index.js");
  JSObjectRef ReactModule = (JSObjectRef)Require(ctx, "node_modules/react/index.js");
  JSObjectRef TextComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule, "Text");
  
  JSObjectRef props = JSObjectMake(ctx, NULL, NULL);
  JSStringRef text = JSStringCreateWithUTF8CString("hello world");
  JSObjectRef createElement = (JSObjectRef)ObjectGet(ctx, ReactModule, "createElement");
  JSValueRef args[3] = { TextComponent, props, JSValueMakeString(ctx, text) };
  JSValueRef element = JSObjectCallAsFunction(ctx, createElement, NULL, 3, args, NULL);
  
  return element;
}

- (void)bridgeDidInitializeJSGlobalContext:(void *)contextRef;
{
  JSGlobalContextRef globalContext = contextRef;
  JSObjectRef globalObject = JSContextGetGlobalObject(globalContext);

  JSStringRef NativeAppComponentName = JSStringCreateWithUTF8CString("NativeAppComponent");
  JSObjectRef functionObject = JSObjectMakeFunctionWithCallback(globalContext, NativeAppComponentName, &NativeAppComponent);
  JSObjectSetProperty(globalContext, globalObject, NativeAppComponentName, functionObject, kJSPropertyAttributeNone, NULL);
  JSStringRelease(NativeAppComponentName);
}

@end
