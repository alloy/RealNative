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

static JSValueRef ObjectCallAsFunctionCallback(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    NSLog(@"HELLLLLOOOOO!");
    return JSValueMakeUndefined(ctx);
}

- (void)bridgeDidInitializeJSGlobalContext:(void *)contextRef;
{
    JSGlobalContextRef globalContext = contextRef;
    JSObjectRef globalObject = JSContextGetGlobalObject(globalContext);
    
    JSStringRef logFunctionName = JSStringCreateWithUTF8CString("log");
    JSObjectRef functionObject = JSObjectMakeFunctionWithCallback(globalContext, logFunctionName, &ObjectCallAsFunctionCallback);

    JSObjectSetProperty(globalContext, globalObject, logFunctionName, functionObject, kJSPropertyAttributeNone, NULL);

  //        JSStringRef logCallStatement = JSStringCreateWithUTF8CString("log()");
  //
  //        JSEvaluateScript(globalContext, logCallStatement, nullptr, nullptr, 1,nullptr);

    JSStringRelease(logFunctionName);
  //        JSStringRelease(logCallStatement);
}


@end
