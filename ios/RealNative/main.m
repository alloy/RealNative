/**
 * This file only has the `.m` extname so `ENABLE_STRICT_OBJC_MSGSEND` can be disabled in the build settings.
 * A PR to change build settings such that `.c` files are also excluded is very welcome.
 */

#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

extern int UIApplicationMain(int, ...);

int main(int argc, char *argv[])
{
  __weak id autoreleasePool = objc_msgSend(objc_msgSend(objc_getClass("NSAutoreleasePool"), sel_registerName("alloc")), sel_registerName("init"));
  UIApplicationMain(argc, argv, nil, CFSTR("AppDelegate"));
  objc_msgSend(autoreleasePool, sel_registerName("drain"));
}
