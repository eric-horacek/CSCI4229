/**
 *  MSScene.h
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */


#import "CC3Scene.h"
#import "MSTouchReceptor.h"

@class MSRobot;

@interface MSScene : CC3Scene <MSTouchReceptor>

@property (nonatomic, strong) CC3PlaneNode* ground;
@property (nonatomic, strong) MSRobot* robot;

- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord;

@end
