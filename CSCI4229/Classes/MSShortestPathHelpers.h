//
//  MSShortestPathHelpers.h
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import <Foundation/Foundation.h>

#define TILE_WIDTH 5
#define TILE_COUNT 100

int tileWidth();
int tileCount();

BOOL validTile(CGPoint tile);
BOOL tileContainsLocation(CGPoint tile, CC3Vector location);

CGPoint tileForLocation(CC3Vector aLocation);
CGPoint tileFractionForLocation(CC3Vector location);

CC3Vector locationForTile(CGPoint tile);

CGRect boundingCoordinatesForTile(CGPoint tile);

