//
//  MSCameraBoom.m
//  CSCI4229
//
//  Created by Eric Horacek on 12/13/12.
//
//

#import "MSCameraBoom.h"
#import "CC3Camera.h"
#import "CGPointExtension.h"

@interface MSCameraBoom ()

@property (nonatomic, assign) CC3Vector cameraStartDirection;

@end

@implementation MSCameraBoom

#pragma mark - MSCameraBoom

- (id)initWithName:(NSString*)aName target:(CC3Node *)target
{
    self = [super initWithName:aName];
    if (self) {
        
        self.target = target;
        
        self.camera = [CC3Camera nodeWithName:@"CameraBoom-Camera"];
        [self addChild:self.camera];
    }
    return self;
}

#pragma mark - MSCameraBoom

- (void)setupCamera
{
    [self.camera moveToShowAllOf:self.target fromDirection:CC3VectorMake(-1.0, 1.0, 0.0) withPadding:3.0];
    // This is necessary again, not sure why
    [self addChild:self.camera];
}

#pragma mark - MSTouchReceptor

- (void)dragStartedAtPoint:(CGPoint)touchPoint
{
    self.cameraStartDirection = self.rotation;
}

- (void)dragMoved:(CGPoint)movement withVelocity:(CGPoint)velocity
{
    CC3Vector cameraDirection = self.cameraStartDirection;
    
    // Scale the pan rotation vector by 180, so that a pan across the entire screen
    // results in a 180 degree pan of the camera
    CGPoint panRotation = ccpMult(movement, 180.0);
	cameraDirection.y -= panRotation.x;
    cameraDirection.z += panRotation.y;
    
    // Prevent from viewing the target upside down
	if (cameraDirection.z < -45.0) {
        cameraDirection.z = -45.0;
    }
    // Prevent from viewing the target from underground
    else if (cameraDirection.z > 45.0) {
        cameraDirection.z = 45.0;
    }
    
    self.rotation = cameraDirection;
}

- (void)dragEnded
{
    self.cameraStartDirection = kCC3VectorNull;
}

@end
