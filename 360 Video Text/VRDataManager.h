//
//  VRDataManager.h
//  360 Video Text
//
//  Created by Nathan Fennel on 10/19/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VRDataManager : NSObject

+ (instancetype)sharedManager;

+ (CGSize)exportingFrameSize;

+ (int)numberOfImagesPerBatch;

+ (float)exportingRatio;

@end
