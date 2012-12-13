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

#import "CC3PODResourceNode.h"
#import "CCActionInterval.h"
#import "CCActionInstant.h"
#import "CC3ActionInterval.h"
#import "CC3Light.h"
#import "CC3ShadowVolumes.h"

@interface MSRobot ()

@property (nonatomic, assign) BOOL avoiding;

@property (nonatomic, strong) NSMutableArray *shortestPathOpenSteps;
@property (nonatomic, strong) NSMutableArray *shortestPathClosedSteps;
@property (nonatomic, strong) NSMutableArray *shortestPath;
@property (nonatomic, strong) CCRepeatForever *walkAction;

- (void)insertInOpenSteps:(MSShortestPathStep *)step;
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord;
- (int)costToMoveFromStep:(MSShortestPathStep *)fromStep toAdjacentStep:(MSShortestPathStep *)toStep;
- (void)constructPathAndStartAnimationFromStep:(MSShortestPathStep *)step;
- (void)popStepAndAnimate;

@end

@implementation MSRobot

- (id)initWithName:(NSString*)aName {
	if ((self = [super initWithName:aName]) ) {
        self.mesh = [CC3PODResourceNode nodeWithName:@"RobotMesh"];
        self.mesh.resource = [CC3PODResource resourceFromFile:@"Robot.pod"];
        [self addChild:self.mesh];
        
        // Rotate the model to display properly in world
        [self.mesh rotateByAngle:97.0 aroundAxis:CC3VectorMake(1.0, 0.0, 0.0)];
        [self.mesh rotateByAngle:-90.0 aroundAxis:CC3VectorMake(0.0, 1.0, 0.0)];
        [self.mesh translateBy:CC3VectorMake(1.7, 1.2, -0.7)];
    
        self.isTouchEnabled = YES;
        self.avoiding = NO;
        
        self.shortestPathClosedSteps = nil;
        self.shortestPathOpenSteps = nil;
        self.shortestPath = nil;
        
        self.velocity = 6.0;
        
        CCActionInterval *walk = [CC3Animate actionWithDuration:0.5];
        self.walkAction = [CCRepeatForever actionWithAction:walk];
        
        // Add a light to illuminate everything in front of the robot with a red glow;
        CC3Light *robotFrontLight = [CC3Light nodeWithName:@"RobotFrontLight"];
        robotFrontLight.isDirectionalOnly = NO;
        robotFrontLight.diffuseColor = CCC4FMake(1.0, 0.0, 0.0, 1.0);
        robotFrontLight.specularColor = CCC4FMake(1.0, 0.0, 0.0, 1.0);
        robotFrontLight.shadowIntensityFactor = 0.75f;
        robotFrontLight.spotCutoffAngle = 50.0;
        robotFrontLight.forwardDirection = cc3v(0.0, -0.5, 1.0);
        robotFrontLight.attenuationCoefficients = CC3AttenuationCoefficientsMake(0.0, 0.3, 0.01);
        
        [self addChild:robotFrontLight];
        robotFrontLight.location = cc3v(0.0, 1.9, 1.4);
        
        self.topLight = [CC3Light nodeWithName:@"self.topLight"];
        self.topLight.location = cc3v(0.0, 8.0, 0.0);;
        self.topLight.attenuationCoefficients = CC3AttenuationCoefficientsMake(0.2, 0.1, 0.001);
        self.topLight.isDirectionalOnly = NO;
        self.topLight.shadowIntensityFactor = 0.75f;
        [self addChild:self.topLight];
        
	}
	return self;
}

- (void)addShadows
{
    [self.mesh addShadowVolumesForLight:self.topLight];
}

- (void)moveToward:(CC3Vector)target {
    
    // Get current tile coordinate and desired tile coord
    CGPoint fromTileCoord = tileForLocation(self.location);
    CGPoint toTileCoord = tileForLocation(target);
    
    if (!validTile(fromTileCoord)) {
        NSLog(@"Current location not on a valid tile!");
        return;
    }
    
    if (!validTile(toTileCoord)) {
        NSLog(@"Destination location not on a valid tile!");
        return;
    }
    
    // Check that there is a path to compute ;-)
    if (CGPointEqualToPoint(fromTileCoord, toTileCoord)) {
        NSLog(@"You're already there! :P");
        return;
    }
    
    // Must check that the desired location is walkable
    // In our case it's really easy, because only wall are unwalkable
    //    if ([_layer isWallAtTileCoord:toTileCoord]) {
    //        [[SimpleAudioEngine sharedEngine] playEffect:@"hitWall.wav"];
    //        return;
    //    }
    
    NSLog(@"From: %@", NSStringFromCGPoint(fromTileCoord));
    NSLog(@"To: %@", NSStringFromCGPoint(toTileCoord));
    
    self.shortestPathOpenSteps = [[NSMutableArray alloc] init];
    self.shortestPathClosedSteps = [[NSMutableArray alloc] init];
    
    // Start by adding the from position to the open list
    [self insertInOpenSteps:[[MSShortestPathStep alloc] initWithPosition:fromTileCoord]];
    
    do {
        // Get the lowest F cost step
        // Because the list is ordered, the first step is always the one with the lowest F cost
        MSShortestPathStep *currentStep = [self.shortestPathOpenSteps objectAtIndex:0];
        
        // Add the current step to the closed set
        [self.shortestPathClosedSteps addObject:currentStep];
        // Remove it from the open list
        [self.shortestPathOpenSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired tile coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, toTileCoord)) {
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
            
            if (index == NSNotFound) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score + the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
                step.hScore = [self computeHScoreFromCoord:step.position toCoord:toTileCoord];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertInOpenSteps:step];
            }
            else { // Already in the open list
                
                step = [self.shortestPathOpenSteps objectAtIndex:index]; // To retrieve the old one (which has its scores already computed ;-)
                
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
    
    if (self.shortestPath == nil) { // No path found
        NSLog(@"NO PATH HAS BEEN FOUND");
    }
    
}

# pragma mark - Shortest Path Helpers

// Insert a path step (ShortestPathStep) in the ordered open steps list (shortestPathOpenSteps)
- (void)insertInOpenSteps:(MSShortestPathStep *)step
{
	int stepFScore = [step fScore]; // Compute the step's F score
	int count = [self.shortestPathOpenSteps count];
	int i = 0; // This will be the index at which we will insert the step
	for (; i < count; i++) {
		if (stepFScore <= [[self.shortestPathOpenSteps objectAtIndex:i] fScore]) { // If the step's F score is lower or equals to the step at index i
			// Then we found the index at which we have to insert the new step
            // Basically we want the list sorted by F score
			break;
		}
	}
	// Insert the new step at the determined index to preserve the F score ordering
	[self.shortestPathOpenSteps insertObject:step atIndex:i];
}

// Compute the H score from a position to another (from the current position to the final desired position
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
    [self.boom stopAllActions];
    
	self.shortestPath = [NSMutableArray array];
    
	do {
		if (step.parent != nil) { // Don't add the last step which is the start position (remember we go backward, so the last one is the origin position ;-)
			[self.shortestPath insertObject:step atIndex:0]; // Always insert at index 0 to reverse the path
		}
		step = step.parent; // Go backward
	} while (step != nil); // Until there is no more parents
    
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
	id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(popStepAndAnimate)]; // set the method itself as the callback
    
	// Remove the step
	[self.shortestPath removeObjectAtIndex:0];
    
	// Play actions
    [self runAction:[CC3RotateToLookAt actionWithDuration:0.3 targetLocation:destination]];
	[self runAction:[CCSequence actions:moveAction, moveCallback, nil]];
    [self.boom runAction:[CC3MoveTo actionWithDuration:walkDuration moveTo:locationForTile(s.position)]];
}

@end
