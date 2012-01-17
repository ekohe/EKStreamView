//
//  EKAppDelegate.h
//  StreamView
//
//  Created by Eli Wang on 1/17/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EKViewController;

@interface EKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) EKViewController *viewController;

@end
