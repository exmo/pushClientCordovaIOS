//
//  AppDelegate+notification.m
//  pushtest
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+notification.h"
#import "PushPlugin.h"
#import <objc/runtime.h>

static char launchNotificationKey;

@implementation AppDelegate (notification)

- (id) getCommandInstance:(NSString*)className
{
	return [self.viewController getCommandInstance:className];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self convertTokenToDeviceID:deviceToken] forKey:@"token"];
    [defaults setObject:[[UIDevice currentDevice] systemVersion] forKey:@"so"];
    [defaults setObject:[[UIDevice currentDevice] name] forKey:@"name"];
    [defaults setObject:[[UIDevice currentDevice] model] forKey:@"device"];
    [defaults synchronize];
    
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    [pushHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    [pushHandler didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveNotification");
    
    
    
    // Get application state for iOS4.x+ devices, otherwise assume active
    UIApplicationState appState = UIApplicationStateActive;
    if ([application respondsToSelector:@selector(applicationState)]) {
        appState = application.applicationState;
    }
    
    if (appState == UIApplicationStateActive) {
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
        pushHandler.notificationMessage = userInfo;
        pushHandler.isInline = YES;
        [pushHandler notificationReceived];
    } else {
        //save it for later
        self.launchNotification = userInfo;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSLog(@"active");
    
    //zero badge
    application.applicationIconBadgeNumber = 0;

    if (![self.viewController.webView isLoading] && self.launchNotification) {
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
        pushHandler.notificationMessage = self.launchNotification;
        
        self.launchNotification = nil;
        
        [pushHandler performSelectorOnMainThread:@selector(notificationReceived) withObject:pushHandler waitUntilDone:NO];
    }
}

// The accessors use an Associative Reference since you can't define a iVar in a category
// http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/objectivec/Chapters/ocAssociativeReferences.html
- (NSMutableArray *)launchNotification
{
   return objc_getAssociatedObject(self, &launchNotificationKey);
}

- (void)setLaunchNotification:(NSDictionary *)aDictionary
{
    objc_setAssociatedObject(self, &launchNotificationKey, aDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    self.launchNotification	= nil; // clear the association and release the object
    [super dealloc];
}


- (NSString *)convertTokenToDeviceID:(NSData *)token {
    NSMutableString *deviceID = [NSMutableString string];
    
    // iterate through the bytes and convert to hex
    unsigned char *ptr = (unsigned char *)[token bytes];
    
    for (NSInteger i=0; i < 32; ++i) {
        [deviceID appendString:[NSString stringWithFormat:@"%02x", ptr[i]]];
    }
    
    return deviceID;
}

@end
