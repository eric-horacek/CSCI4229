//
//  MSRobot.m
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import "MSRobot.h"
#import "MSScene.h"
#import "MSShortestPathStep.h"
#import "MSShortestPathHelpers.h"
#import "MSCameraBoom.h"

#import "CC3PODResourceNode.h"
#import "CCActionInterval.h"
#import "CCActionInstant.h"
#import "CC3ActionInterval.h"
#import "CC3Light.h"
#import "CC3ShadowVolumes.h"
#import "CGPointExtension.h"

@interface MSRobot ()

@property (nonatomic, strong) NSMutableArray *shortestPathOpenSteps;
@property (nonatomic, strong) NSMutableArray *shortestPathClosedSteps;
@property (nonatomic, strong) NSMutableArray *shortestPath;
@property (nonatomic, strong) CCRepeatForever *walkAction;
@property (nonatomic, assign) BOOL togglingCamera;

@property (nonatomic, assign) CC3Vector cameraStartDirection;

- (void)insertInOpenSteps:(MSShortestPathStep *)step;
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord;
- (int)costToMoveFromStep:(MSShortestPathStep *)fromStep toAdjacentStep:(MSShortestPathStep *)toStep;
- (void)constructPathAndStartAnimationFromStep:(MSShortestPathStep *)step;
- (void)popStepAndAnimate;

@end

@implementation MSRobot

- (id)initWithName:(NSString*)aName parent:(CC3Node *)aParent
{
	if ((self = [super initWithName:aName]) ) {
        
        self.mesh = [CC3PODResourceNode nodeWithName:@"RobotMesh"];
        self.mesh.resource = [CC3PODResource resourceFromFile:@"Robot.pod"];
        [self addChild:self.mesh];
        
        // Rotate the model to display properly in world
        [self.mesh rotateByAngle:97.0 aroundAxis:CC3VectorMake(1.0, 0.0, 0.0)];
        [self.mesh rotateByAngle:-90.0 aroundAxis:CC3VectorMake(0.0, 1.0, 0.0)];
        [self.mesh translateBy:CC3VectorMake(1.7, 1.0, -0.7)];
    
        self.isTouchEnabled = YES;
        
        // Pathfinding
        
        self.shortestPathClosedSteps = nil;
        self.shortestPathOpenSteps = nil;
        self.shortestPath = nil;
        
        self.velocity = 12.0;
        
        // Animations
        
        CCActionInterval *walk = [CC3Animate actionWithDuration:0.25];
        self.walkAction = [CCRepeatForever actionWithAction:walk];
        
        // Camera
        
        self.togglingCamera = NO;
        
        self.firstPersonCamera = [CC3Camera nodeWithName:@"RobotFirstPersonCamera"];
        [self addChild:self.firstPersonCamera];
        self.firstPersonCamera.location = cc3v(0.0, 2.5, 1.5);
        self.firstPersonCamera.forwardDirection = cc3v(0.0, 0.0, 1.0);

        self.transitionCamera = [CC3Camera nodeWithName:@"RobotTransitionCamera"];
        [self addChild:self.transitionCamera];
        
        self.cameraBoom = [[MSCameraBoom alloc] initWithName:@"RobotCameraBoom" target:self];
        // We don't want the camera boom to be a child of ourself, but of our parent
        [aParent addChild:self.cameraBoom];
        
        // Lighting
        
        // Add a light to illuminate everything in front of the robot with a red glow;
        self.frontLight = [CC3Light nodeWithName:@"RobotFrontLight"];
        self.frontLight.isDirectionalOnly = NO;
        self.frontLight.diffuseColor = CCC4FMake(1.0, 0.0, 0.0, 1.0);
        self.frontLight.specularColor = CCC4FMake(1.0, 0.0, 0.0, 1.0);
        self.frontLight.shadowIntensityFactor = 0.75f;
        self.frontLight.spotCutoffAngle = 50.0;
        self.frontLight.forwardDirection = cc3v(0.0, -0.5, 1.0);
        self.frontLight.attenuationCoefficients = CC3AttenuationCoefficientsMake(0.0, 0.3, 0.01);
        [self addChild:self.frontLight];
        self.frontLight.location = cc3v(0.0, 1.9, 1.4);
        
        // Add a light to illuminate the robot from the top
        self.topLight = [CC3Light nodeWithName:@"RobotTopLight"];
        self.topLight.location = cc3v(0.0, 8.0, 0.0);;
        self.topLight.attenuationCoefficients = CC3AttenuationCoefficientsMake(0.2, 0.1, 0.001);
        self.topLight.isDirectionalOnly = NO;
        self.topLight.shadowIntensityFactor = 0.75f;
        [self addChild:self.topLight];
        
        [aParent addChild:self];
        
        // This needs to happen after we add the robot as a child of the parent
        [self addShadows];
	}
	return self;
}

- (void)addShadows
{
    [self.mesh addShadowVolumesForLight:self.topLight];
}

- (void)removeShadows
{
    [self.mesh removeShadowVolumesForLight:self.topLight];
}

- (void)toggleCameras
{
    if (self.togglingCamera == YES) {
        return;
    }
    
    if (self.scene.activeCamera == self.firstPersonCamera) {
        
        self.togglingCamera = YES;
        
        [self removeShadows];
        [self.scene addChild:self.transitionCamera];
        
        self.transitionCamera.location = self.firstPersonCamera.globalLocation;
        self.transitionCamera.rotation = self.firstPersonCamera.globalRotation;
        
        self.scene.activeCamera = self.transitionCamera;
        
        id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(setActiveCameraToBoomCamera)];
        CC3MoveTo *moveAction = [CC3MoveTo actionWithDuration:0.5 moveTo:self.cameraBoom.camera.globalLocation];
        [self.transitionCamera runAction:[CC3RotateTo actionWithDuration:0.5 rotateTo:self.cameraBoom.camera.globalRotation]];
        [self.transitionCamera runAction:[CCSequence actions:moveAction, moveCallback, nil]];
        
	} else if (self.activeCamera == self.cameraBoom.camera) {
        
        self.togglingCamera = YES;
        
        [self removeShadows];
        [self.scene addChild:self.transitionCamera];
        
        self.transitionCamera.location = self.cameraBoom.camera.globalLocation;
        self.transitionCamera.rotation = self.cameraBoom.camera.globalRotation;
        
        self.scene.activeCamera = self.transitionCamera;
        
        id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(setActiveCameraToFirstPersonCamera)];
        CC3MoveTo *moveAction = [CC3MoveTo actionWithDuration:0.5 moveTo:self.firstPersonCamera.globalLocation];
        [self.transitionCamera runAction:[CC3RotateTo actionWithDuration:0.5 rotateTo:self.firstPersonCamera.globalRotation]];
        [self.transitionCamera runAction:[CCSequence actions:moveAction, moveCallback, nil]];
	}
}

- (void)setActiveCameraToBoomCamera
{
    self.scene.activeCamera = self.cameraBoom.camera;
    self.togglingCamera = NO;
    [self addShadows];
}

- (void)setActiveCameraToFirstPersonCamera
{
    self.scene.activeCamera = self.firstPersonCamera;
    self.togglingCamera = NO;
}

- (void)rotateFirstPersonCameraToForward
{
    [self.firstPersonCamera runAction:[CC3RotateTo actionWithDuration:0.3 rotateTo:CC3VectorMake(self.firstPersonCamera.rotation.x, -180.0, self.firstPersonCamera.rotation.z)]];
}

- (void)moveToward:(CC3Vector)target
{
    [self stopAllActions];
    [self.cameraBoom stopAllActions];
    [self rotateFirstPersonCameraToForward];
    self.shortestPath = [@[[[MSShortestPathStep alloc] initWithPosition:tileFractionForLocation(target)]] mutableCopy];
    [self runAction:self.walkAction];
    [self popStepAndAnimate];
}

- (void)navigateToward:(CC3Vector)target
{
    [self rotateFirstPersonCameraToForward];
    
    CGPoint sourceTile = tileForLocation(self.location);
    CGPoint destinationTile = tileForLocation(target);
    
    if (!validTile(sourceTile)) {
        NSLog(@"Current location not on a valid tile!");
        return;
    }
    
    if (!validTile(destinationTile)) {
        NSLog(@"Destination location not on a valid tile!");
        return;
    }
    
    // Check that there is a path to compute
    if (CGPointEqualToPoint(sourceTile, destinationTile)) {
        NSLog(@"You are already there!");
        return;
    }
    
    NSLog(@"From: %@", NSStringFromCGPoint(sourceTile));
    NSLog(@"To: %@", NSStringFromCGPoint(destinationTile));
    
    self.shortestPathOpenSteps = [[NSMutableArray alloc] init];
    self.shortestPathClosedSteps = [[NSMutableArray alloc] init];
    
    // Start by adding the from position to the open list
    [self insertInOpenSteps:[[MSShortestPathStep alloc] initWithPosition:sourceTile]];
    
    do {
        // Get the lowest F cost step
        // Because the list is ordered, the first step is always the one with the lowest F cost
        MSShortestPathStep *currentStep = [self.shortestPathOpenSteps objectAtIndex:0];
        
        // Add the current step to the closed set
        [self.shortestPathClosedSteps addObject:currentStep];
        // Remove it from the open list
        [self.shortestPathOpenSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired tile coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, destinationTile)) {
            [self constructPathAndStartAnimationFromStep:currentStep];
            break;
        }
        
        // Get the adjacent tiles coord of the current step
        NSArray *adjSteps = [((MSScene *)self.scene) walkableAdjacentTilesCoordForTileCoord:currentStep.position];
        for (NSValue *v in adjSteps) {
            MSShortestPathStep *step = [[MSShortestPathStep alloc] initWithPosition:[v CGPointValue]];
            
            // Check if the step isn't already in the closed set
            if ([self.shortestPathClosedSteps containsObject:step]) {
                continue; // Ignore it
            }
            
            // Compute the cost from the current step to that step
            int moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list
            NSUInteger index = [self.shortestPathOpenSteps indexOfObject:step];
            
            // Not on the open list, so add it
            if (index == NSNotFound) {
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score + the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
                step.hScore = [self computeHScoreFromCoord:step.position toCoord:destinationTile];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertInOpenSteps:step];
            }
            // Already in the open list
            else {
                
                // Retrieve the old one (which has its scores already computed)
                step = [self.shortestPathOpenSteps objectAtIndex:index];
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep.gScore + moveCost) < step.gScore) {
                    
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    step.gScore = currentStep.gScore + moveCost;
                
                    // Because the G Score has changed, the F score may have changed too
                    // So to keep the open list ordered we have to remove the step, and re-insert it with
                    // the insert function which is preserving the list ordered by F score
                    [self.shortestPathOpenSteps removeObjectAtIndex:index];
                    
                    // Re-insert it with the function which is preserving the list ordered by F score
                    [self insertInOpenSteps:step];
                }
            }
        }
        
    } while ([self.shortestPathOpenSteps count] > 0);
    
    if (self.shortestPath == nil) {
        NSLog(@"No path found");
    }
    
}

# pragma mark - Shortest Path Helpers

// Insert a path step in the ordered open steps list
- (void)insertInOpenSteps:(MSShortestPathStep *)step
{
    // Compute the step's F score
	int stepFScore = [step fScore];
	int count = [self.shortestPathOpenSteps count];
	int i = 0; // This will be the index at which we will insert the step
	for (; i < count; i++) {
		if (stepFScore <= [[self.shortestPathOpenSteps objectAtIndex:i] fScore]) {
            // If the step's F score is lower or equals to the step at index i
			// Then we found the index at which we have to insert the new step
            // Basically we want the list sorted by F score
			break;
		}
	}
	// Insert the new step at the determined index to preserve the F score ordering
	[self.shortestPathOpenSteps insertObject:step atIndex:i];
}

// Compute the H score from a position to another (from the current position to the final desired position)
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord
{
	// Here we use the Manhattan method, which calculates the total number of step moved horizontally and vertically to reach the
	// final desired step from the current step, ignoring any obstacles that may be in the way
	return abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
}

// Compute the cost of moving from a step to an adjacent one
- (int)costToMoveFromStep:(MSShortestPathStep *)fromStep toAdjacentStep:(MSShortestPathStep *)toStep
{
    return ((fromStep.position.x != toStep.position.x) && (fromStep.position.y != toStep.position.y)) ? 14 : 10;
}

// Go backward from a step (the final one) to reconstruct the shortest computed path
- (void)constructPathAndStartAnimationFromStep:(MSShortestPathStep *)step
{
    [self stopAllActions];
    [self.cameraBoom stopAllActions];
    
	self.shortestPath = [NSMutableArray array];
    
	do {
		if (step.parent != nil) {
			// Don't add the last step which is the start position
            // Always insert at index 0 to reverse the path
            [self.shortestPath insertObject:step atIndex:0];
		}
        // Go backward
		step = step.parent;
	} while (step != nil);
    
    for (MSShortestPathStep *s in self.shortestPath) {
        NSLog(@"%@", s);
    }
    
    [self runAction:self.walkAction];
    [self popStepAndAnimate];
}

- (void)popStepAndAnimate
{
    // Check if there remains path steps to go through
	if ([self.shortestPath count] == 0) {
        [self stopAction:self.walkAction];
		self.shortestPath = nil;
		return;
	}
    
	// Get the next step to move to
	MSShortestPathStep *s = [self.shortestPath objectAtIndex:0];
    
    CC3Vector destination = locationForTile(s.position);
    
    CGFloat distance = CC3VectorDistance(self.location, destination);
    CGFloat walkDuration = distance / self.velocity;

	// Prepare the action and the callback
    id moveAction = [CC3MoveTo actionWithDuration:walkDuration moveTo:destination];
    // Set the method itself as the callback
	id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(popStepAndAnimate)];
    
	// Remove the step
	[self.shortestPath removeObjectAtIndex:0];
    
	// Play actions
    [self runAction:[CC3RotateToLookAt actionWithDuration:0.3 targetLocation:destination]];
	[self runAction:[CCSequence actions:moveAction, moveCallback, nil]];
    [self.cameraBoom runAction:[CC3MoveTo actionWithDuration:walkDuration moveTo:locationForTile(s.position)]];
}

#pragma mark - MSTouchReceptor

- (void)dragStartedAtPoint:(CGPoint)touchPoint;
{
    if (self.scene.activeCamera == self.firstPersonCamera) {
        self.cameraStartDirection = self.firstPersonCamera.rotation;
	} else if (self.activeCamera == self.cameraBoom.camera) {
        [self.cameraBoom dragStartedAtPoint:touchPoint];
    }
}

- (void)dragMoved:(CGPoint)movement withVelocity:(CGPoint)velocity;
{
    if (self.scene.activeCamera == self.firstPersonCamera && !self.togglingCamera) {

        CC3Vector cameraDirection = self.cameraStartDirection;
        
        // Scale the pan rotation vector by 180, so that a pan across the entire screen
        // results in a 180 degree pan of the camera
        CGPoint panRotation = ccpMult(movement, 100.0);
        cameraDirection.y -= panRotation.x;
        cameraDirection.x += panRotation.y;
        
        // Prevent from viewing the robot upside down
        if (cameraDirection.x < -45.0) {
            cameraDirection.x = -45.0;
        }
        // Prevent from viewing the robot from underground
        else if (cameraDirection.x > 45.0) {
            cameraDirection.x = 45.0;
        }
        
        // Prevent from viewing the robot upside down
        if (cameraDirection.y < -275.0) {
            cameraDirection.y = -275.0;
        }
        // Prevent from viewing the robot from underground
        else if (cameraDirection.y > -90.0) {
            cameraDirection.y = -90.0;
        }
        
        self.firstPersonCamera.rotation = cameraDirection;
        
	} else if (self.activeCamera == self.cameraBoom.camera) {
        
        [self.cameraBoom dragMoved:movement withVelocity:velocity];
    }
}

- (void)dragEnded
{
    if (self.scene.activeCamera == self.firstPersonCamera) {
        self.cameraStartDirection = kCC3VectorNull;
    } else if (self.activeCamera == self.cameraBoom.camera) {
        [self.cameraBoom dragEnded];
    }
}

- (void)pinchStarted
{
    if (self.scene.activeCamera == self.firstPersonCamera) {
        [self toggleCameras];
    } else if (self.activeCamera == self.cameraBoom.camera) {
        [self.cameraBoom pinchStarted];
    }
}

- (void)pinchChangedScale:(CGFloat)aScale withVelocity:(CGFloat)aVelocity
{
    if (aVelocity > 8.0 && self.activeCamera == self.cameraBoom.camera) {
        [self toggleCameras];
    } else if (!self.togglingCamera) {
        [self.cameraBoom pinchChangedScale:aScale withVelocity:aVelocity];
    }
}

- (void)pinchEnded
{
    [self.cameraBoom pinchStarted];
}

@end
