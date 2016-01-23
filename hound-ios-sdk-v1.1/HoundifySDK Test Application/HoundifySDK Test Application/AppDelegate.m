//
//  AppDelegate.m
//  HoundifySDK Test Application
//
//  Created by Cyril Austin on 10/29/15.
//  Copyright © 2015 SoundHound, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <HoundSDK/HoundSDK.h>

#pragma mark - AppDelegate

@interface AppDelegate()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    #warning - insert the credentials provided by SoundHound
    
    [Hound setClientID:@"<INSERT YOUR CLIENT ID>"];
    [Hound setClientKey:@"<INSERT YOUR CLIENT KEY>"];
    
    return YES;
}

@end
