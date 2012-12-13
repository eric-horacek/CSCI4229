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

@property (nonatomic, assign) CC3Vector dragStartRotation;
@property (nonatomic, assign) CC3Vector dragStartCameraLocation;

@end

@implementation MSCameraBoom

#pragma mark - MSCameraBoom

- (id)initWithName:(NSString*)aName target:(CC3Node *)target
{
    self = [super initWithName:aName];
    if (self) {
        
        self.target = target;
        
        self.maxDistance = 50.0;
        self.minDistance = 10.0;
        
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

- (CGFloat)cameraDistance
{
    return CC3VectorLength(self.camera.location);
}

#pragma mark - MSTouchReceptor

- (void)dragStartedAtPoint:(CGPoint)touchPoint
{
    self.dragStartRotation = self.rotation;
}

- (void)dragMoved:(CGPoint)movement withVelocity:(CGPoint)velocity
{
    CC3Vector rotation = self.dragStartRotation;
    
    // Scale the pan rotation vector by 180, so that a pan across the entire screen
    // results in a 180 degree pan of the camera
    CGPoint panRotation = ccpMult(movement, 180.0);
	rotation.y -= panRotation.x;
    rotation.z += panRotation.y;
    
    // Prevent from viewing the target upside down
	if (rotation.z < -45.0) {
        rotation.z = -45.0;
    }
    // Prevent from viewing the target from underground
    else if (rotation.z > 45.0) {
        rotation.z = 45.0;
    }
    
    self.rotation = rotation;
}

- (void)dragEnded
{
    self.dragStartRotation = kCC3VectorNull;
}

- (void)pinchStarted
{
    self.dragStartCameraLocation = self.camera.location;
}

- (void)pinchChangedScale:(CGFloat)aScale withVelocity:(CGFloat)aVelocity
{
    CC3Vector cameraLocation = self.dragStartCameraLocation;
    
    GLfloat moveDist = logf(aScale) * 50.0;
	CC3Vector moveVector = CC3VectorScaleUniform(self.camera.forwardDirection, moveDist);
	cameraLocation = CC3VectorAdd(cameraLocation, moveVector);
    
    // If we're more than 50 out
    if (CC3VectorLength(cameraLocation) > self.maxDistance) {
        cameraLocation = self.camera.location;
    }
    // If we're less than 5 in
    if (CC3VectorLength(cameraLocation) < self.minDistance) {
        cameraLocation = self.camera.location;
    }
    if (cameraLocation.y < 0.0) {
        cameraLocation = self.camera.location;
    }
    
    self.camera.location = cameraLocation;
}

- (void)pinchEnded
{
    self.dragStartCameraLocation = kCC3VectorNull;
}

@end
