#import "AppDelegate.h"

#import <JavaScriptCore/JavaScriptCore.h>
#import <Block.h>

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
CreateElement(
  JSContextRef ctx,
  JSObjectRef component,
  JSObjectRef props,
  size_t childCount,
  JSValueRef *children
) {
  JSObjectRef ReactModule = (JSObjectRef)Require(ctx, "node_modules/react/index.js");
  JSObjectRef createElement = (JSObjectRef)ObjectGet(ctx, ReactModule, "createElement");

  JSValueRef error = NULL;
  JSObjectRef childArray = JSObjectMakeArray(ctx, childCount, children, &error);
  if (error) {
    ConsoleLog(ctx, error);
    return NULL;
  }

  if (props == NULL) {
    props = JSObjectMake(ctx, NULL, NULL);
  }

  JSValueRef args[3] = { component, props, childArray };
  JSValueRef element = JSObjectCallAsFunction(ctx, createElement, NULL, 3, args, NULL);
  return element;
}

static JSObjectRef
ReactNativeModule(JSContextRef ctx) {
  return (JSObjectRef)Require(ctx, "node_modules/react-native/index.js");
}

static JSValueRef
RenderContainerComponent(JSContextRef ctx, size_t childCount, JSValueRef *children) {
  JSObjectRef ViewComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule(ctx), "View");

  JSObjectRef containerStyle = JSObjectMake(ctx, NULL, NULL);
  ObjectSetNumber(ctx, containerStyle, "flex", 1);
//  ObjectSetString(ctx, containerStyle, "backgroundColor", "red");
  ObjectSetString(ctx, containerStyle, "justifyContent", "center");
  ObjectSetString(ctx, containerStyle, "alignItems", "center");
  
  JSObjectRef containerProps = JSObjectMake(ctx, NULL, NULL);
  ObjectSetValue(ctx, containerProps, "style", containerStyle);
  
  JSValueRef element = CreateElement(ctx, ViewComponent, containerProps, childCount, children);
  return element;
}

static JSValueRef
PewPewPeeeeeewButtonComponent(
  JSContextRef ctx,
  JSObjectRef function,
  JSObjectRef thisObject,
  size_t argumentCount,
  const JSValueRef arguments[],
  JSValueRef* exception
) {
  JSObjectRef RNButtonComponent = (JSObjectRef)ObjectGet(ctx, ReactNativeModule(ctx), "Button");
  JSObjectRef props = JSObjectMake(ctx, NULL, NULL);
  ObjectSetString(ctx, props, "title", "pew pew peeeeeew");
  JSValueRef element = CreateElement(ctx, RNButtonComponent, props, 0, NULL);
  
  return element;
}
static JSObjectRef
GetPewPewPeeeeeewButtonComponent(JSContextRef ctx) {
  static char *componentName = "PewPewpeeeeeewButtonComponent";
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSObjectRef component = (JSObjectRef)ObjectGet(ctx, globalObject, componentName);
  if (component == JSValueMakeUndefined(ctx)) {
    JSStringRef jsComponentName = JSStringCreateWithUTF8CString(componentName);
    component = JSObjectMakeFunctionWithCallback(ctx, jsComponentName, &PewPewPeeeeeewButtonComponent);
    JSStringRelease(jsComponentName);
    ObjectSetValue(ctx, globalObject, componentName, component);
  }
  return component;
}

static JSValueRef
RenderButtonComponent(JSContextRef ctx) {
  JSObjectRef ButtonComponent = GetPewPewPeeeeeewButtonComponent(ctx);
  JSValueRef element = CreateElement(ctx, ButtonComponent, NULL, 0, NULL);
  return element;
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
  JSValueRef children[1] = { RenderButtonComponent(ctx) };
  JSValueRef element = RenderContainerComponent(ctx, 1, children);
  return element;
}

static void
DefineComponent(JSContextRef ctx, char *name, JSObjectCallAsFunctionCallback implementation) {
  JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
  JSStringRef jsName = JSStringCreateWithUTF8CString(name);
  
  JSClassDefinition definition = {
    
  };
  JSClassRef klass = JSClassCreate(<#const JSClassDefinition *definition#>)
  
  JSObjectCallAsFunctionCallback impl = Block_copy(implementation);
  JSObjectRef functionObject = JSObjectMakeFunctionWithCallback(ctx, jsName, impl);
  ObjectSetValue(ctx, globalObject, name, functionObject);
  JSStringRelease(jsName);
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
