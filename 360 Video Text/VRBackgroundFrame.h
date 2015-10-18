//
//  VRBackgroundFrame.h
//  360 Video Text
//
//  Created by Nathan Fennel on 10/17/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VRBackgroundFrame : NSObject

@property (nonatomic, strong) UIImage *image;

//@property (nonatomic) CGRect frame;

@property (nonatomic) CGFloat pitchInDegrees;
@property (nonatomic) CGFloat rollInDegrees;
@property (nonatomic) CGFloat yawInDegrees;



@end
