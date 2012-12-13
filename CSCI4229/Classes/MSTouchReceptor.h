//
//  MSTouch.h
//  CSCI4229
//
//  Created by Eric Horacek on 12/13/12.
//
//

#import <Foundation/Foundation.h>

@protocol MSTouchReceptor <NSObject>

@optional

- (void)dragStartedAtPoint:(CGPoint)touchPoint;
- (void)dragMoved:(CGPoint)movement withVelocity:(CGPoint)velocity;
- (void)dragEnded;

- (void)pinchStarted;
- (void)pinchChangedScale:(CGFloat)scale withVelocity:(CGFloat)velocity;
- (void)pinchEnded;

@end
