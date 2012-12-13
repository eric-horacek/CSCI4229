//
//  MSCameraBoom.h
//  CSCI4229
//
//  Created by Eric Horacek on 12/13/12.
//
//

#import "CC3Node.h"
#import "MSTouchReceptor.h"

@interface MSCameraBoom : CC3Node <MSTouchReceptor>

@property (nonatomic, strong) CC3Camera *camera;
@property (nonatomic, weak) CC3Node *target;

- (id)initWithName:(NSString*)aName target:(CC3Node *)target;

- (void)setupCamera;

@end
