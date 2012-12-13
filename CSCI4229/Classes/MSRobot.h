//
//  MSRobot.h
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import "CC3Node.h"

@class CC3PODResourceNode;

@interface MSRobot : CC3Node

@property (nonatomic, strong) CC3PODResourceNode *mesh;
@property (nonatomic, strong) CC3Node *boom;
@property (nonatomic, assign) CGFloat velocity;

- (void)moveToward:(CC3Vector)target;

@end
