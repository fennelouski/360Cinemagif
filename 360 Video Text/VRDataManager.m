//
//  VRDataManager.m
//  360 Video Text
//
//  Created by Nathan Fennel on 10/19/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import "VRDataManager.h"
#import <UIKit/UIKit.h>

@implementation VRDataManager {
    CGSize frameSize;
}

+ (instancetype)sharedManager {
    static VRDataManager *sharedDataManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataManager = [[VRDataManager alloc] init];
    });

    return sharedDataManager;
}

- (CGSize)exportingFrameSize {
    int width = 1024;
    while (width % 32 != 0) {
        width++;
    }
    
    int height = width/2;
    
    return (CGSize){width, height};//I'm aware that it's backwards
}

+ (int)numberOfImagesPerBatch {
    return 3000;
}

@end
