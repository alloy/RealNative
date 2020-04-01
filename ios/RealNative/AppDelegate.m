/**
 * This file only has the `.m` extname so `ENABLE_STRICT_OBJC_MSGSEND` can be disabled in the build settings.
 * A PR to change build settings such that `.c` files are also excluded is very welcome.
 */

#import <objc/runtime.h>
#import <objc/message.h>

#import "Components.h"

struct AppDelegate
{
    Class isa;
    id window;
};

Class AppDelegateClass;

static void
InitializeFlipper(void *application)
{
  id layoutDescriptorMapper = objc_msgSend(objc_msgSend(objc_getClass("SKDescriptorMapper"), sel_getUid("alloc")), sel_getUid("initWithDefaults"));
  id layoutPlugin = objc_msgSend(objc_msgSend(objc_getClass("FlipperKitLayoutPlugin"), sel_getUid("alloc")), sel_getUid("initWithRootNode:withDescriptorMapper:"), application, layoutDescriptorMapper);
  id userDefaultsPlugin = objc_msgSend(objc_msgSend(objc_getClass("FKUserDefaultsPlugin"), sel_getUid("alloc")), sel_getUid("initWithSuiteName:"), NULL);
  id reactPlugin = objc_msgSend(objc_getClass("FlipperKitReactPlugin"), sel_getUid("new"));
  id networkPlugin = objc_msgSend(objc_msgSend(objc_getClass("FlipperKitNetworkPlugin"), sel_getUid("alloc")), sel_getUid("initWithNetworkAdapter:"), objc_msgSend(objc_getClass("SKIOSNetworkAdapter"), sel_getUid("new")));

  id flipperClient = objc_msgSend(objc_getClass("FlipperClient"), sel_getUid("sharedClient"));
  objc_msgSend(flipperClient, sel_getUid("addPlugin:"), layoutPlugin);
  objc_msgSend(flipperClient, sel_getUid("addPlugin:"), userDefaultsPlugin);
  objc_msgSend(flipperClient, sel_getUid("addPlugin:"), reactPlugin);
  objc_msgSend(flipperClient, sel_getUid("addPlugin:"), networkPlugin);
  objc_msgSend(flipperClient, sel_getUid("start"));
}

BOOL
AppDelegate_didFinishLaunching(struct AppDelegate *self, SEL _cmd, void *application, void *options)
{
  InitializeFlipper(application);

  id bridge = objc_msgSend(objc_msgSend(objc_getClass("RCTBridge"), sel_getUid("alloc")), sel_getUid("initWithDelegate:launchOptions:"), self, NULL);
  id rootView = objc_msgSend(objc_msgSend(objc_getClass("RCTRootView"), sel_getUid("alloc")), sel_getUid("initWithBridge:moduleName:initialProperties:"), bridge, CFSTR("RealNative"), NULL);

  CGRect (*getBounds)(id receiver, SEL operation);
  getBounds = (CGRect (*)(id, SEL))objc_msgSend_stret;
  CGRect screenRect = getBounds(objc_msgSend(objc_getClass("UIScreen"), sel_getUid("mainScreen")), sel_getUid("bounds"));
  self->window = objc_msgSend(objc_getClass("UIWindow"), sel_getUid("alloc"));
  self->window = objc_msgSend(self->window, sel_getUid("initWithFrame:"), screenRect);

  id viewController = objc_msgSend(objc_msgSend(objc_getClass("UIViewController"), sel_getUid("alloc")), sel_getUid("init"));
  objc_msgSend(viewController, sel_getUid("setView:"), rootView);
  objc_msgSend(self->window, sel_getUid("setRootViewController:"), viewController);
  objc_msgSend(self->window, sel_getUid("makeKeyAndVisible"));

  return YES;
}

id
AppDelegate_window(struct AppDelegate *self, SEL _cmd)
{
  return self->window;
}

id
AppDelegate_sourceURLForBridge(struct AppDelegate *self, SEL _cmd, id bridge)
{
  return objc_msgSend(objc_msgSend(objc_getClass("RCTBundleURLProvider"), sel_getUid("sharedSettings")), sel_getUid("jsBundleURLForBundleRoot:fallbackResource:"), CFSTR("index"), NULL);
}

static void
AppDelegate_bridgeDidInitializeJSGlobalContext(struct AppDelegate *self, SEL _cmd, void *contextRef)
{
  DefineComponents((JSGlobalContextRef)contextRef);
}

__attribute__((constructor))
static void InitializeAppDelegate()
{
  AppDelegateClass = objc_allocateClassPair(objc_getClass("UIResponder"), "AppDelegate", 0);
  class_addIvar(AppDelegateClass, "window", sizeof(id), 0, "@");
  class_addMethod(AppDelegateClass, sel_getUid("window"), (IMP)AppDelegate_window, "i@:");
  class_addMethod(AppDelegateClass, sel_getUid("application:didFinishLaunchingWithOptions:"), (IMP)AppDelegate_didFinishLaunching, "i@:@@");
  class_addMethod(AppDelegateClass, sel_getUid("sourceURLForBridge:"), (IMP)AppDelegate_sourceURLForBridge, "i@:@");
  class_addMethod(AppDelegateClass, sel_getUid("bridgeDidInitializeJSGlobalContext:"), (IMP)AppDelegate_bridgeDidInitializeJSGlobalContext, "i@:@^v");
  objc_registerClassPair(AppDelegateClass);
}
