/**
 *  MSLayer.m
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */

#import "MSLayer.h"
#import "MSScene.h"
#import "CC3CC2Extensions.h"
#import "CC3IOSExtensions.h"

@implementation MSLayer

- (MSScene*)scene
{
    return (MSScene*) cc3Scene;
}

- (void)dealloc
{
    [super dealloc];
}

//
// Override to set up your 2D controls and other initial state.
//
// For more info, read the notes of this method on CC3Layer.
//
- (void)initializeControls
{
    
}

#pragma mark Updating layer

//
// Override to perform set-up activity prior to the scene being opened
// on the view, such as adding gesture recognizers.
//
// For more info, read the notes of this method on CC3Layer.
//
- (void)onOpenCC3Layer
{

	// Register for tap gestures to select 3D nodes.
	UITapGestureRecognizer* tapSelector = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(handleTapSelection:)];
	tapSelector.numberOfTapsRequired = 1;
	tapSelector.cancelsTouchesInView = NO; // Ensures touches are passed to buttons
	[self cc3AddGestureRecognizer: tapSelector];
	[tapSelector release];
    
    // Register for single-finger dragging gestures used to rotate the camera
	UIPanGestureRecognizer* dragPanner = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(handleDrag:)];
	dragPanner.minimumNumberOfTouches = 1;
	dragPanner.maximumNumberOfTouches = 1;
	[self cc3AddGestureRecognizer: dragPanner];
    [dragPanner release];
}


- (void)handleTapSelection:(UITapGestureRecognizer*)gesture
{
    
	// Once the gesture has ended, convert the UI location to a 2D node location and
	// pick the 3D node under that location. Don't forget to test that the gesture is
	// valid and does not conflict with touches handled by this layer or its descendants.
	if ([self cc3ValidateGesture: gesture] && (gesture.state == UIGestureRecognizerStateEnded)) {
		CGPoint touchPoint = [self cc3ConvertUIPointToNodeSpace: gesture.location];
		[self.scene pickNodeFromTapAt:touchPoint];
	}
}

- (void)handleDrag:(UIPanGestureRecognizer*) gesture
{
	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
			if ([self cc3ValidateGesture: gesture]) {
				[self.scene startDraggingAt:[self cc3ConvertUIPointToNodeSpace:gesture.location]];
			}
			break;
		case UIGestureRecognizerStateChanged:
			[self.scene dragBy:[self cc3NormalizeUIMovement:gesture.translation] atVelocity:[self cc3NormalizeUIMovement:gesture.velocity]];
			break;
		case UIGestureRecognizerStateEnded:
			[self.scene stopDragging];
			break;
		default:
			break;
	}
}

//
// Override to perform tear-down activity prior to the scene disappearing.
//
// For more info, read the notes of this method on CC3Layer.
//
- (void)onCloseCC3Layer
{
}

@end