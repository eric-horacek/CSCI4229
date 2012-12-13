//
//  MSRobot.h
//  CSCI4229
//
//  Created by Devon Tivona on 12/12/12.
//
//

#import "CC3Node.h"
#import "MSTouchReceptor.h"

@class CC3PODResourceNode, CC3Light, MSCameraBoom;

@interface MSRobot : CC3Node <MSTouchReceptor>

@property (nonatomic, strong) CC3PODResourceNode *mesh;
@property (nonatomic, strong) MSCameraBoom *cameraBoom;
@property (nonatomic, assign) CGFloat velocity;
@property (nonatomic, strong) CC3Light *topLight;
@property (nonatomic, strong) CC3Light *frontLight;
@property (nonatomic, strong) CC3Camera *firstPersonCamera;

- (id)initWithName:(NSString*)aName parent:(CC3Node *)parent;

- (void)navigateToward:(CC3Vector)target;
- (void)moveToward:(CC3Vector)target;
- (void)addShadows;

- (void)toggleCameras;

@end
