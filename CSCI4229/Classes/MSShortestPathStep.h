//
//  MSShortestPathStep.h
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import <Foundation/Foundation.h>

@interface MSShortestPathStep : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) int gScore;
@property (nonatomic, assign) int hScore;
@property (nonatomic, assign) MSShortestPathStep *parent;

- (id)initWithPosition:(CGPoint)pos;
- (int)fScore;

@end
