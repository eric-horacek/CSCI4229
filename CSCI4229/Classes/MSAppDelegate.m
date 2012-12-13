/**
 *  MSAppDelegate.m
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */

#import "MSAppDelegate.h"
#import "MSLayer.h"
#import "MSScene.h"
#import "CC3EAGLView.h"

#define kAnimationFrameRate	60 // Animation frame rate

@implementation MSAppDelegate {
	UIWindow *window;
	CC3DeviceCameraOverlayUIViewController *viewController;
}

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
	// Establish the type of CCDirector to use.
	// Try to use CADisplayLink director and if it fails (SDK < 3.1) use the default director.
	// This must be the first thing we do and must be done before establishing view controller.
	if(![CCDirector setDirectorType:kCCDirectorTypeDisplayLink]) {
        [CCDirector setDirectorType:kCCDirectorTypeDefault];
    }
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images.
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565. You can change anytime.
	CCTexture2D.defaultAlphaPixelFormat = kCCTexture2DPixelFormat_RGBA8888;
	
	// Create the view controller for the 3D view.
	viewController = [CC3DeviceCameraOverlayUIViewController new];
	viewController.supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
	
	// Create the CCDirector, set the frame rate, and attach the view.
	CCDirector *director = CCDirector.sharedDirector;
	director.runLoopCommon = YES; // Improves display link integration with UIKit
	director.animationInterval = (1.0f / kAnimationFrameRate);
	director.displayFPS = YES;
	director.openGLView = viewController.view;
	
	// Enables High Res mode on Retina Displays and maintains low res on all other devices
	// This must be done after the GL view is assigned to the director!
	[director enableRetinaDisplay: YES];
	
	// Create the window, make the controller (and its view) the root of the window, and present the window
	window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
	[window addSubview: viewController.view];
	window.rootViewController = viewController;
	[window makeKeyAndVisible];

	// Cocos3D Setup
	
	// Create the customized CC3Layer that supports 3D rendering and schedule it for automatic updates.
	CC3Layer* cc3Layer = [MSLayer node];
	[cc3Layer scheduleUpdate];
	
	// Create the customized 3D scene and attach it to the layer.
	// Could also just create this inside the customer layer.
	cc3Layer.cc3Scene = [MSScene scene];
	
	// Assign to a generic variable so we can uncomment options below to play with the capabilities
	CC3ControllableLayer* mainLayer = cc3Layer;
	
	// Attach the layer to the controller and run a scene with it.
	[viewController runSceneOnNode: mainLayer];
}


-(void) applicationDidBecomeActive: (UIApplication*) application
{
    [CCDirector.sharedDirector resume];
}

- (void)applicationDidReceiveMemoryWarning: (UIApplication*) application
{
	[CCDirector.sharedDirector purgeCachedData];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	[CCDirector.sharedDirector stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
	[CCDirector.sharedDirector startAnimation];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	[CCDirector.sharedDirector.openGLView removeFromSuperview];
	[CCDirector.sharedDirector end];
}

- (void)applicationSignificantTimeChange:(UIApplication*)application
{
	[CCDirector.sharedDirector setNextDeltaTimeZero: YES];
}

@end
