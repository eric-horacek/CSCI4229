//
//  MSShortestPathStep.m
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import "MSShortestPathStep.h"

@implementation MSShortestPathStep

- (id)initWithPosition:(CGPoint)aPosition
{
	if ((self = [super init])) {
		self.position = aPosition;
		self.gScore = 0;
		self.hScore = 0;
		self.parent = nil;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@  pos=[%.0f;%.0f]  g=%d  h=%d  f=%d", [super description], self.position.x, self.position.y, self.gScore, self.hScore, [self fScore]];
}

- (BOOL)isEqual:(MSShortestPathStep *)other
{
	return CGPointEqualToPoint(self.position, other.position);
}

- (int)fScore
{
	return self.gScore + self.hScore;
}


@end
