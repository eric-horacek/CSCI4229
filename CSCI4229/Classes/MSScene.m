/**
 *  MSScene.m
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */

#import "MSScene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3ParametricMeshNodes.h"
#import "CGPointExtension.h"
#import "CCLabelTTF.h"
#import "CC3Billboard.h"
#import "CCActionInstant.h"
#import "CCParticleExamples.h"
#import "CC3ShadowVolumes.h"
#import "CC3VertexArrays.h"
#import "CC3BoundingVolumes.h"
#import "CC3ModelSampleFactory.h"

#import "MSRobot.h"
#import "MSShortestPathHelpers.h"

#import "MSCameraBoom.h"

#define DEBUG3D

@interface MSScene ()

@property (nonatomic, strong) NSArray *treeTiles;

- (void)addGround;
- (void)addRobot;
- (void)addForest;

- (void)addTeapotsForLightsWithParent:(CCNode *)parentNode;
- (void)addExampleLandscape;

- (void)toogleRobotFirstPerson;

@end

@implementation MSScene

#pragma mark - Scene Lifecycle

- (void)initializeScene
{
    self.ambientLight = CCC4FMake(0.0, 0.0, 0.0, 0.3);
    
    [self addGround];
//    [self addCameraBoom];
    [self addForest];
    [self addRobot];
    
//    self.robot.boom = self.boom;

#if defined(DEBUG3D)
    [self addTeapotsForLightsWithParent:(CCNode *)self];
#endif
	
	// Create OpenGL ES buffers for the vertex arrays to keep things fast and efficient,
	// and to save memory, release the vertex data in main memory because it is now redundant.
    [self retainVertexLocations];
	[self retainVertexIndices];
	[self retainVertexWeights];
	[self retainVertexMatrixIndices];
	[self createGLBuffers];
	[self releaseRedundantData];
    	
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
    // self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
    // self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
    // self.shouldDrawAllWireframeBoxes = YES;
    // self.shouldDrawAllBoundingVolumes = YES;
    // self.shouldLogIntersections = YES;
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogCleanDebug(@"The structure of this scene is: %@", [self structureDescription]);
}

- (void)onOpen
{
    self.activeCamera = self.robot.cameraBoom.camera;
    [self.robot.cameraBoom setupCamera];
}

- (void) onClose
{
    
}

#pragma mark - Object Addition Methods

- (void)addGround
{
    self.ground = [CC3PlaneNode nodeWithName:@"Ground"];
    
    CGFloat gridTotalSize = 25.0;
    
    [self.ground populateAsCenteredRectangleWithSize:CGSizeMake(0.001, 0.001)];
    
    for (CGFloat x = -(gridTotalSize / 2.0); x <= (gridTotalSize / 2.0); x += 1.0) {
        for (CGFloat z = -(gridTotalSize / 2.0); z <= (gridTotalSize / 2.0); z += 1.0) {
            CC3PlaneNode *groundSegment = [CC3PlaneNode nodeWithName:[NSString stringWithFormat:@"%f-%f", x, z]];
            [groundSegment populateAsRectangleWithSize:CGSizeMake(10.0, 10.0) andRelativeOrigin:CGPointMake(x, z) andTessellation:ccg(16, 16)];
            groundSegment.color = ccGRAY;
            groundSegment.texture = [CC3Texture textureFromFile:@"Grass.jpg"];
            [groundSegment repeatTexture: (ccTex2F){1.0, 1.0}];
            [self.ground addChild:groundSegment];
        }
    }
    
	self.ground.location = cc3v(0.0, 0.0, 0.0);
	self.ground.rotation = cc3v(-90.0, 180.0, 0.0);
    
	self.ground.shouldCullBackFaces = NO; // Show the ground from below as well.
	self.ground.isTouchEnabled = YES;
	[self.ground retainVertexLocations];
	[self addChild:self.ground];
}

- (void)addRobot
{
    self.robot = [[MSRobot alloc] initWithName:@"Robot" parent:self];
    
#if defined(DEBUG3D)
    self.robot.shouldDrawWireframeBox = YES;
    [self.robot addAxesDirectionMarkers];
#endif
}

- (void)addForest
{
    NSMutableArray *mutableTreeTiles = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        
        NSString *treeName = [NSString stringWithFormat:@"Tree_%d", i];
        
        [self addContentFromPODFile:@"Tree.pod" withName:treeName];
        
        CC3MeshNode *tree = (CC3MeshNode*)[self getNodeNamed:treeName];
        
        CC3MeshNode *treeTrunk = (CC3MeshNode*)[tree getNodeNamed:@"tree-submesh0"];
        treeTrunk.color = ccc3(76.0, 38.0, 0.0);
        treeTrunk.material.shininess = 16.0;
        
        CC3MeshNode *treeLeaves = (CC3MeshNode*)[tree getNodeNamed:@"tree-submesh1"];
        treeLeaves.color = ccc3(64.0, 128.0, 0.0);
        treeLeaves.texture = [CC3Texture textureFromFile:@"Grass.jpg"];
        [treeLeaves repeatTexture: (ccTex2F){1.0, 1.0}];
        
        CC3Vector treeTileLocation = CC3VectorMake(rand() % 100 + 5, 0, rand() % 100 + 5);
    
        CGPoint treeTile = tileForLocation(treeTileLocation);
        CC3Vector treeLocation = locationForTile(treeTile);
        
        tree.location = treeLocation;
        tree.isTouchEnabled = YES;
            
        // This causes EXTREME lag (to the point of not rendering any frames), not sure why
        // [tree addShadowVolumesForLight:(CC3Light *)[self.robot getNodeNamed:@"RobotTopLight"]];
        
        [mutableTreeTiles addObject:[NSValue valueWithCGPoint:treeTile]];

        #if defined(DEBUG3D)
        tree.shouldDrawWireframeBox = YES;
        #endif
    }
    self.treeTiles = [mutableTreeTiles copy];
    
    #if defined(DEBUG3D)
    for (NSValue *value in self.treeTiles) {
        CGPoint point = [value CGPointValue];

        CC3PlaneNode *plane = [CC3PlaneNode nodeWithName:[NSString stringWithFormat:@"%d", rand()]];
        [plane populateAsCenteredRectangleWithSize:CGSizeMake(tileWidth(), tileWidth())];

        plane.rotation = cc3v(-90.0, 180.0, 0.0);
        CC3Vector newLocation = locationForTile(point);
        newLocation.y = 0.1;
        plane.location = newLocation;

        plane.color = ccGRAY;
        plane.shouldCullBackFaces = NO;
        [self addChild:plane];
    }
    #endif
}

- (void)addExampleLandscape
{
    NSUInteger gridSize = 10.0;
    NSUInteger gridSpace = 20.0;
    for (CGFloat x = -((gridSize / 2.0) * gridSpace); x <= ((gridSize / 2.0) * gridSpace); x += gridSpace) {
        for (CGFloat z = -((gridSize / 2.0) * gridSpace); z <= ((gridSize / 2.0) * gridSpace); z += gridSpace) {
            CC3MeshNode *teapot = [[CC3ModelSampleFactory factory] makeUniColoredTeapotNamed:@"RobotLightTeapot" withColor:ccc4f(1.0, 1.0, 1.0, 1.0)];
            teapot.uniformScale = 10.0;
            [self addChild:teapot];
            teapot.location = cc3v(x, 2.0, z);
        }
    }
}

- (void)addTeapotsForLightsWithParent:(CCNode *)parentNode
{
    for (CCNode *node in parentNode.children) {
        if ([node isKindOfClass:CC3Light.class]) {
            CC3Light *light = (CC3Light *)node;
            CC3MeshNode *lightMarker = [[CC3ModelSampleFactory factory] makeUniColoredTeapotNamed:@"RobotLightTeapot" withColor:CCC4FFromColorAndOpacity(light.color, 0.5)];
            lightMarker.uniformScale = 3.0;
            lightMarker.rotation = light.forwardDirection;
            [light addChild:lightMarker];
            [lightMarker addAxesDirectionMarkers];
        }
        [self addTeapotsForLightsWithParent:node];
    }
}

#pragma mark - Update Custom Activity

//
// This template method is invoked periodically whenever the 3D nodes are to be updated.
//
// This method provides your app with an opportunity to perform update activities before
// any changes are applied to the transformMatrix of the 3D nodes in the scene.
//
// For more info, read the notes of this method on CC3Node.
//
- (void)updateBeforeTransform:(CC3NodeUpdatingVisitor*)visitor
{
}

//
// This template method is invoked periodically whenever the 3D nodes are to be updated.
//
// This method provides your app with an opportunity to perform update activities after
// the transformMatrix of the 3D nodes in the scen have been recalculated.
//
// For more info, read the notes of this method on CC3Node.
//
- (void)updateAfterTransform:(CC3NodeUpdatingVisitor*)visitor {
    [self checkForCollisions];
	// If you have uncommented the moveWithDuration: invocation in the onOpen: method,
	// you can uncomment the following to track how the camera moves, and where it ends up,
	// in order to determine where to position the camera to see the entire scene.
    // LogDebug(@"Camera location is: %@", NSStringFromCC3Vector(activeCamera.globalLocation));
}


#pragma mark - Touch Event Handlers 

// This callback template method is invoked automatically when a node has been picked
// by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
// as a result of a touch event or tap gesture.
- (void)nodeSelected:(CC3Node*)node byTouchEvent:(uint)touchType at:(CGPoint)touchPoint
{
    if (node == self.robot) {
        NSLog(@"Touched my robot");
        [self.robot toggleCameras];
    }
    else if (node == self.ground) {
        NSLog(@"Touched my ground");
        [self touchGroundAt:touchPoint];
    }
}

- (void)dragStartedAtPoint:(CGPoint)touchPoint
{
//    self.cameraStartDirection = self.boom.rotation;
    [self.robot dragStartedAtPoint:touchPoint];
}

- (void)dragMoved:(CGPoint)movement withVelocity:(CGPoint)velocity
{    
//    CC3Vector cameraDirection = self.cameraStartDirection;
//    
//    // Scale the pan rotation vector by 180, so that a pan across the entire screen
//    // results in a 180 degree pan of the camera
//    CGPoint panRotation = ccpMult(movement, 180.0);
//	cameraDirection.y -= panRotation.x;
//    cameraDirection.z += panRotation.y;
//    
//    // Prevent from viewing the robot upside down
//	if (cameraDirection.z < -45.0) {
//        cameraDirection.z = -45.0;
//    }
//    // Prevent from viewing the robot from underground
//    else if (cameraDirection.z > 45.0) {
//        cameraDirection.z = 45.0;
//    }
//    
//    self.boom.rotation = cameraDirection;
    [self.robot dragMoved:movement withVelocity:velocity];
}

- (void)dragEnded
{
    [self.robot dragEnded];
}

- (void)touchGroundAt:(CGPoint)touchPoint
{
	CC3Plane groundPlane = self.ground.plane;
	CC3Vector4 touchLoc = [self.activeCamera unprojectPoint:touchPoint ontoPlane:groundPlane];
    
	// Make sure the projected touch is in front of the camera, not behind it
	if (touchLoc.w > 0.0) {        
        CC3Vector destinationLocation = CC3VectorFromTruncatedCC3Vector4(touchLoc);
        CGPoint destinationTile = tileForLocation(destinationLocation);
        if ([self isTreeTile:destinationTile]) {
            NSLog(@"That's a tree tile! We don't want to go there!");
        } else if (!validTile(destinationTile)) {
            NSLog(@"That's not a valid tile! We don't want to go there!");
        } else if (CC3VectorDistance(self.robot.location, destinationLocation) > 50){
            NSLog(@"That's too far away! We don't want to go there!");
        } else if (![self treeTileBetweenSource:self.robot.location andTarget:destinationLocation]) {
            NSLog(@"No need to calculate shortest path! Here we go!");
            [self addExplosionAt:touchLoc];
            [self.robot moveToward:destinationLocation];
        } else {
            [self addExplosionAt:touchLoc];
            [self.robot navigateToward:destinationLocation];
        }
	}
}

/**
 * Adds a temporary fiery explosion on top of the specified node, using a cocos2d
 * CCParticleSystem. The explosion is set to a short duration, and when the particle
 * system has exhausted, the CC3ParticleSystem node along with the CCParticleSystem
 * billboard it contains are automatically removed from the 3D scene.
 */
- (void)addExplosionAt:(CC3Vector4)explosionLocation {
	// Create the particle emitter with a finite duration, and set it to auto-remove
	// once it is exhausted.
	CCParticleSystem* emitter = [CCParticleFire node];
	emitter.position = ccp(0.0, 0.0);
	emitter.duration = 0.2;
	emitter.autoRemoveOnFinish = YES;
    
	// Create the 3D billboard node to hold the 2D particle emitter.
	// The bounding volume is removed so that the flames will not be culled as the
	// camera pans away from the flames. This is suitable since the particle system
	// only exists for a short duration.
	CC3ParticleSystemBillboard* bb = [CC3ParticleSystemBillboard nodeWithName:@"Explosion" withBillboard:emitter];
	
	// A billboard can be drawn either as part of the 3D scene, or as an overlay
	// above the 3D scene. By commenting out one of the following sections of code,
	// you can choose which method to use.
	
	// 1) In the 3D scene.
	// The following lines wrap the emitter billboard in a wrapper that will find
	// and track the camera in 3D. The flames can be occluded by other nodes between
	// the explosion and the camera.
    
	bb.uniformScale = 0.03;	// Find a suitable scale
	bb.shouldUseLighting = NO;								// Solid coloring
	bb.shouldInheritTouchability = NO;						// Don't allow flames to be touched
    
	// If the 2D particle system uses point particles instead of quads, attenuate the
	// particle sizes with distance realistically. This is not needed if the particle
	// system will always use quads, but it doesn't hurt to set it.
	bb.particleSizeAttenuationCoefficients = CC3AttenuationCoefficientsMake(0.05, 0.02, 0.0001);
	
	// 2D particle systems do not have a real contentSize and boundingBox, so we need to
	// calculate it dynamically on each update pass, or assign one that will cover the
	// area that will be used by this particular particle system. This bounding rectangle
	// is specified in terms of the local coordinate system of the particle system and
	// will be scaled and transformed as the node is transformed. By setting this once,
	// we don't need to calculate it while running the particle system.
	// To calculate it dynamically on each update instead, comment out the following line,
	// and uncomment the line after. And also uncomment the third line to see the bounding
	// box drawn and updated on each frame.
	bb.billboardBoundingRect = CGRectMake(-90.0, -30.0, 190.0, 300.0);
    // bb.shouldAlwaysMeasureBillboardBoundingRect = YES;
    
    #if defined(DEBUG3D)
        bb.shouldDrawLocalContentWireframeBox = YES;
    #endif
    
	// How did we determine the billboardBoundingRect? This can be done by trial and
	// error, by uncommenting culling logging in the CC3Billboard doesIntersectBoundingVolume:
	// method. Or it is better done by changing LogTrace to LogDebug in the CC3Billboard
	// billboardBoundingRect property accessor method, commenting out the line above this
	// comment, and uncommenting the following line. Doing so will cause an ever expanding
	// bounding box to be logged, the maximum size of which can be used as the value to
	// set in the billboardBoundingRect property.
    //	bb.shouldMaximizeBillboardBoundingRect = YES;
    
	// We want to locate the explosion between the node and the camera, so that it
	// appears to engulf the node. To do this, wrap the billboard in an orientating
	// wrapper, give the explosion a location offset, and make the wrapper track
	// the camera. This will keep the explosion between the node and the camera,
	// regardless of where they are.
	// If we didn't need the locational offset to place the explosion in front
	// of the camera, we could have the billboard itself track the camera
	// using the shouldAutotargetCamera property of the billboard itself.
	bb.location = CC3VectorFromTruncatedCC3Vector4(explosionLocation);
    bb.location = CC3VectorAdd(bb.location, CC3VectorMake(0.0, 1.0, 0.0));
    bb.shouldAutotargetCamera = YES;
	[self addChild:bb];
    
	// 2) Overlaid above the 3D scene.
	// The following lines add the emitter billboard as a 2D overlay that draws above
	// the 3D scene. The flames will not be occluded by any other 3D nodes.
	// Comment out the lines in section (1) just above, and uncomment the following lines:
    //	emitter.positionType = kCCPositionTypeGrouped;
    //	bb.shouldDrawAs2DOverlay = YES;
    //	bb.unityScaleDistance = 180.0;
    //	[aNode addChild: bb];
}

#pragma mark - Collision Detection

- (void)checkForCollisions
{
    for (int i = 0; i < 10; i++) {
        NSString *treeName = [NSString stringWithFormat:@"Tree_%d", i];
        CC3Node *tree = [self getNodeNamed:treeName];
        
        CC3Node *treeNode = [tree getNodeNamed:@"tree-submesh0"];
        CC3Node *robotNode = [self.robot getNodeNamed:@"Cube_001-submesh0"];
    
        if ([robotNode doesIntersectNode:treeNode]) {
            // A collision has occured!
        }
    }
}

# pragma mark - Shortest Path Helpers

- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord
{
	NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:8];
    
    BOOL t = NO;
    BOOL l = NO;
    BOOL b = NO;
    BOOL r = NO;
    
	// Top
	CGPoint p = CGPointMake(tileCoord.x, tileCoord.y - 1);
	if (validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
	}
    
	// Left
	p = CGPointMake(tileCoord.x - 1, tileCoord.y);
	if (validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
        l = YES;
	}
    
	// Bottom
	p = CGPointMake(tileCoord.x, tileCoord.y + 1);
	if (validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
        b = YES;
	}
    
	// Right
	p = CGPointMake(tileCoord.x + 1, tileCoord.y);
	if (validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
        r = YES;
	}
    
    
	// Top Left
	p = CGPointMake(tileCoord.x - 1, tileCoord.y - 1);
	if (t && l && validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Bottom Left
	p = CGPointMake(tileCoord.x - 1, tileCoord.y + 1);
	if (b && l && validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Top Right
	p = CGPointMake(tileCoord.x + 1, tileCoord.y - 1);
	if (t && r && validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Bottom Right
	p = CGPointMake(tileCoord.x + 1, tileCoord.y + 1);
	if (b && r && validTile(p) && ![self isTreeTile:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
    
	return [NSArray arrayWithArray:tmp];
}

- (BOOL)treeTileBetweenSource:(CC3Vector)source andTarget:(CC3Vector)target
{
    CC3Ray sourceRay = CC3RayFromLocDir(source, CC3VectorDifference(target, source));
    CC3Ray destinationRay = CC3RayFromLocDir(target, CC3VectorDifference(source, target));
    
    for (NSValue *value in self.treeTiles) {
        CGPoint point = [value CGPointValue];
        CC3Vector boxLocation = locationForTile(point);
        
        CC3BoundingBox boundingBox = CC3BoundingBoxMake(boxLocation.x - tileWidth(),
                                                        -5.0,
                                                        boxLocation.z - tileWidth(),
                                                        boxLocation.x + tileWidth(),
                                                        5.0,
                                                        boxLocation.z + tileWidth());
        
        if (!CC3VectorIsNull(CC3RayIntersectionOfBoundingBox(sourceRay, boundingBox)) &&
            !CC3VectorIsNull(CC3RayIntersectionOfBoundingBox(destinationRay, boundingBox))) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isTreeTile:(CGPoint)tile
{
    for (NSValue *value in self.treeTiles) {
        CGPoint point = [value CGPointValue];
        if (CGPointEqualToPoint(point, tile)) {
            return YES;
        }
    }
    return NO;
}

@end
