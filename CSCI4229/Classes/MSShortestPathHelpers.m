//
//  MSShortestPathHelpers.c
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import "MSShortestPathHelpers.m"
#import "CC3VertexArrays.h"

#define TILE_WIDTH 4
#define TILE_COUNT 375

int tileWidth()
{
    return TILE_WIDTH;
}

int tileCount()
{
    return TILE_COUNT;
}

BOOL validTile(CGPoint tile)
{
    if (tile.x > 0 && tile.x < 2*TILE_COUNT) {
        if (tile.y > 0 && tile.y < 2*TILE_COUNT) {
            return YES;
        }
    }
    return NO;
}

CC3Vector locationForTile(CGPoint tile)
{
    CC3Vector location = CC3VectorMake(tile.x * TILE_WIDTH + TILE_WIDTH/2, 0, tile.y * TILE_WIDTH + TILE_WIDTH/2);
    location.x -= (TILE_WIDTH*TILE_COUNT)/2;
    location.z -= (TILE_WIDTH*TILE_COUNT)/2;
    return location;
}

CGPoint tileForLocation(CC3Vector location)
{
    CGPoint point = CGPointMake(location.x + (TILE_WIDTH*TILE_COUNT)/2, location.z + (TILE_WIDTH*TILE_COUNT)/2);
    point.x /= TILE_WIDTH;
    point.x = floorf(point.x);
    
    point.y /= TILE_WIDTH;
    point.y = floorf(point.y);
    
    return point;
}

CGPoint tileFractionForLocation(CC3Vector location)
{
    CGPoint point = CGPointMake(location.x + (TILE_WIDTH*TILE_COUNT)/2, location.z + (TILE_WIDTH*TILE_COUNT)/2);
    point.x /= TILE_WIDTH;
    point.y /= TILE_WIDTH;
    return point;
}

CGRect boundingCoordinatesForTile(CGPoint tile)
{
    CGRect rect = CGRectMake(tile.x * TILE_WIDTH, tile.y * TILE_WIDTH, TILE_WIDTH, TILE_WIDTH);
    return rect;
}

BOOL tileContainsLocation(CGPoint tile, CC3Vector location)
{
    CGRect boundingRect = boundingCoordinatesForTile(tile);
    CGPoint point = CGPointMake(location.x, location.z);
    return CGRectContainsPoint(boundingRect, point);
}