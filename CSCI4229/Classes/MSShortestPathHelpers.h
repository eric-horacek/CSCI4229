//
//  MSShortestPathHelpers.h
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import <Foundation/Foundation.h>

BOOL validTile(CGPoint tile);
CGPoint tileForLocation(CC3Vector aLocation);
CC3Vector locationForTile(CGPoint tile);
CGRect boundingCoordinatesForTile(CGPoint tile);
BOOL tileContainsLocation(CGPoint tile, CC3Vector location);
