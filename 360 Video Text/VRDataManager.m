//
//  VRDataManager.m
//  360 Video Text
//
//  Created by Nathan Fennel on 10/19/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import "VRDataManager.h"
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation VRDataManager {
    CGSize frameSize;
	CGSize exportingFrameSize;
	float exportingRatio;
	int batchSize;
}

+ (instancetype)sharedManager {
    static VRDataManager *sharedDataManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataManager = [[VRDataManager alloc] init];
    });
	
    return sharedDataManager;
}

- (instancetype)init {
	self = [super init];
	
	if (self) {
		exportingRatio = [self outputRatio];
		batchSize = [self batchSize];
	}
	
	return self;
}

+ (CGSize)exportingFrameSize {
	return [[VRDataManager sharedManager] exportingFrameSize];
}

- (CGSize)exportingFrameSize {
	if (exportingFrameSize.width == 0) {
		int width = 1024;
		while (width % 32 != 0) {
			width++;
		}
		
		int height = width/2;
		
		exportingFrameSize = CGSizeMake(width, height);
	}
	
	return exportingFrameSize;
}

+ (float)exportingRatio {
	return [[VRDataManager sharedManager] outputRatio];
}

+ (int)numberOfImagesPerBatch {
    return [[VRDataManager sharedManager] batchSize];
}



- (NSString *) platform{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithUTF8String:machine];
	free(machine);
	return platform;
}

- (float)outputRatio {
	NSString *platform = [self platform];
	
	if ([platform isEqualToString:@"iPhone1,1"])    return 0.12f; //@"iPhone 1G";
	if ([platform isEqualToString:@"iPhone1,2"])    return 0.12f; //@"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"])    return 0.12f; //@"iPhone 3GS";
	if ([platform isEqualToString:@"iPhone3,1"])    return 0.12f; //@"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,3"])    return 0.12f; //@"Verizon iPhone 4";
	if ([platform isEqualToString:@"iPhone4,1"])    return 0.12f; //@"iPhone 4S";
	if ([platform isEqualToString:@"iPhone5,1"])    return 0.12f; //@"iPhone 5 (GSM)";
	if ([platform isEqualToString:@"iPhone5,2"])    return 0.12f; //@"iPhone 5 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone5,3"])    return 0.12f; //@"iPhone 5c (GSM)";
	if ([platform isEqualToString:@"iPhone5,4"])    return 0.12f; //@"iPhone 5c (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone6,1"])    return 0.115f; //@"iPhone 5s (GSM)";
	if ([platform isEqualToString:@"iPhone6,2"])    return 0.115f; //@"iPhone 5s (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone7,1"])    return 0.12f; //@"iPhone 6 Plus";
	if ([platform isEqualToString:@"iPhone7,2"])    return 0.12f; //@"iPhone 6";
	if ([platform isEqualToString:@"iPhone8,1"])    return 0.12f; //@"iPhone 6s Plus";
	if ([platform isEqualToString:@"iPhone8,2"])    return 0.12f; //@"iPhone 6s";
	if ([platform isEqualToString:@"iPod1,1"])      return 0.12f; //@"iPod Touch 1G";
	if ([platform isEqualToString:@"iPod2,1"])      return 0.12f; //@"iPod Touch 2G";
	if ([platform isEqualToString:@"iPod3,1"])      return 0.12f; //@"iPod Touch 3G";
	if ([platform isEqualToString:@"iPod4,1"])      return 0.12f; //@"iPod Touch 4G";
	if ([platform isEqualToString:@"iPod5,1"])      return 0.12f; //@"iPod Touch 5G";
	if ([platform isEqualToString:@"iPad1,1"])      return 0.1562f; //@"iPad";
	if ([platform isEqualToString:@"iPad2,1"])      return 0.1562f; //@"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,2"])      return 0.1562f; //@"iPad 2 (GSM)";
	if ([platform isEqualToString:@"iPad2,3"])      return 0.1562f; //@"iPad 2 (CDMA)";
	if ([platform isEqualToString:@"iPad2,4"])      return 0.1562f; //@"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,5"])      return 0.1562f; //@"iPad Mini (WiFi)";
	if ([platform isEqualToString:@"iPad2,6"])      return 0.1562f; //@"iPad Mini (GSM)";
	if ([platform isEqualToString:@"iPad2,7"])      return 0.1562f; //@"iPad Mini (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,1"])      return 0.1562f; //@"iPad 3 (WiFi)";
	if ([platform isEqualToString:@"iPad3,2"])      return 0.1562f; //@"iPad 3 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,3"])      return 0.1562f; //@"iPad 3 (GSM)";
	if ([platform isEqualToString:@"iPad3,4"])      return 0.1562f; //@"iPad 4 (WiFi)";
	if ([platform isEqualToString:@"iPad3,5"])      return 0.1562f; //@"iPad 4 (GSM)";
	if ([platform isEqualToString:@"iPad3,6"])      return 0.1562f; //@"iPad 4 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad4,1"])      return 0.1562f; //@"iPad Air (WiFi)";
	if ([platform isEqualToString:@"iPad4,2"])      return 0.1562f; //@"iPad Air (Cellular)";
	if ([platform isEqualToString:@"iPad4,4"])      return 0.1562f; //@"iPad mini 2G (WiFi)";
	if ([platform isEqualToString:@"iPad4,5"])      return 0.1562f; //@"iPad mini 2G (Cellular)";
	if ([platform isEqualToString:@"i386"])         return 0.11; //@"Simulator";
	if ([platform isEqualToString:@"x86_64"])       return 0.1; //@"Simulator";
	
	return 0.1562f;
}

- (int)batchSize {
	NSString *platform = [self platform];
	
	if ([platform isEqualToString:@"iPhone1,1"])    return 5; //@"iPhone 1G";
	if ([platform isEqualToString:@"iPhone1,2"])    return 5; //@"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"])    return 5; //@"iPhone 3GS";
	if ([platform isEqualToString:@"iPhone3,1"])    return 15; //@"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,3"])    return 30; //@"Verizon iPhone 4";
	if ([platform isEqualToString:@"iPhone4,1"])    return 60; //@"iPhone 4S";
	if ([platform isEqualToString:@"iPhone5,1"])    return 120; //@"iPhone 5 (GSM)";
	if ([platform isEqualToString:@"iPhone5,2"])    return 120; //@"iPhone 5 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone5,3"])    return 120; //@"iPhone 5c (GSM)";
	if ([platform isEqualToString:@"iPhone5,4"])    return 120; //@"iPhone 5c (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone6,1"])    return 240; //@"iPhone 5s (GSM)";
	if ([platform isEqualToString:@"iPhone6,2"])    return 240; //@"iPhone 5s (GSM+CDMA)";
	if ([platform isEqualToString:@"iPhone7,1"])    return 300; //@"iPhone 6 Plus";
	if ([platform isEqualToString:@"iPhone7,2"])    return 300; //@"iPhone 6";
	if ([platform isEqualToString:@"iPhone8,1"])    return 300; //@"iPhone 6s Plus";
	if ([platform isEqualToString:@"iPhone8,2"])    return 300; //@"iPhone 6s";
	if ([platform isEqualToString:@"iPod1,1"])      return 5; //@"iPod Touch 1G";
	if ([platform isEqualToString:@"iPod2,1"])      return 5; //@"iPod Touch 2G";
	if ([platform isEqualToString:@"iPod3,1"])      return 5; //@"iPod Touch 3G";
	if ([platform isEqualToString:@"iPod4,1"])      return 5; //@"iPod Touch 4G";
	if ([platform isEqualToString:@"iPod5,1"])      return 5; //@"iPod Touch 5G";
	if ([platform isEqualToString:@"iPad1,1"])      return 240; //@"iPad";
	if ([platform isEqualToString:@"iPad2,1"])      return 240; //@"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,2"])      return 240; //@"iPad 2 (GSM)";
	if ([platform isEqualToString:@"iPad2,3"])      return 240; //@"iPad 2 (CDMA)";
	if ([platform isEqualToString:@"iPad2,4"])      return 240; //@"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,5"])      return 240; //@"iPad Mini (WiFi)";
	if ([platform isEqualToString:@"iPad2,6"])      return 240; //@"iPad Mini (GSM)";
	if ([platform isEqualToString:@"iPad2,7"])      return 240; //@"iPad Mini (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,1"])      return 240; //@"iPad 3 (WiFi)";
	if ([platform isEqualToString:@"iPad3,2"])      return 240; //@"iPad 3 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,3"])      return 240; //@"iPad 3 (GSM)";
	if ([platform isEqualToString:@"iPad3,4"])      return 240; //@"iPad 4 (WiFi)";
	if ([platform isEqualToString:@"iPad3,5"])      return 240; //@"iPad 4 (GSM)";
	if ([platform isEqualToString:@"iPad3,6"])      return 240; //@"iPad 4 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad4,1"])      return 240; //@"iPad Air (WiFi)";
	if ([platform isEqualToString:@"iPad4,2"])      return 240; //@"iPad Air (Cellular)";
	if ([platform isEqualToString:@"iPad4,4"])      return 240; //@"iPad mini 2G (WiFi)";
	if ([platform isEqualToString:@"iPad4,5"])      return 240; //@"iPad mini 2G (Cellular)";
	if ([platform isEqualToString:@"i386"])         return 120; //@"Simulator";
	if ([platform isEqualToString:@"x86_64"])       return 240; //@"Simulator";
	
	return 0.1562f;
}
@end
