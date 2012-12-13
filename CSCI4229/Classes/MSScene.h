/**
 *  MSScene.h
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */


#import "CC3Scene.h"

@class MSRobot;

@interface MSScene : CC3Scene

@property (nonatomic, strong) CC3PlaneNode* ground;
@property (nonatomic, strong) MSRobot* robot;

- (void)startDraggingAt:(CGPoint)touchPoint;
- (void)dragBy:(CGPoint)movement atVelocity:(CGPoint)velocity;
- (void)stopDragging;


- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord;

@end
