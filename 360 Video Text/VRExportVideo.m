//
//  VRExportVideo.m
//  360 Video Text
//
//  Created by Nathan Fennel on 10/18/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import "VRExportVideo.h"
#import "VRDataManager.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define kScreenWidth (([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)

@implementation VRExportVideo

+ (void)saveMovieToLibrary:(NSArray *)images {
    NSLog(@"+ (void)saveMovieToLibrary:(NSArray *)images");
    [[VRExportVideo new] saveMovieToLibrary:images];
}

- (void)saveMovieToLibrary:(NSArray *)images {
    NSLog(@"- (void)saveMovieToLibrary:(NSArray *)images");
    // You just need the height and width of the video here
    // For us, our input and output video was 640 height x 480 width
    // which is what we get from the iOS front camera
    int height = [[VRDataManager sharedManager] exportingFrameSize].height;
    int width = [[VRDataManager sharedManager] exportingFrameSize].width;
    
    // You can save a .mov or a .mp4 file
    //NSString *fileNameOut = @"temp.mp4";
    NSString *fileNameOut = @"temp.mov";
    
    // We chose to save in the tmp/ directory on the device initially
    NSString *directoryOut = @"tmp/";
    NSString *outFile = [NSString stringWithFormat:@"%@%@",directoryOut,fileNameOut];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", outFile]];
    NSURL *videoTempURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileNameOut]];
    
    // WARNING: AVAssetWriter does not overwrite files for us, so remove the destination file if it already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[videoTempURL path]  error:NULL];
    
    
    [self writeImageAsMovie:images toPath:path size:CGSizeMake(height, width)];
}

-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size {
    NSLog(@"-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size ");
    NSError *error = nil;
    
    // FIRST, start up an AVAssetWriter instance to write your video
    // Give it a destination path (for us: tmp/temp.mov)
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];

    //Start a SESSION of writing.
    // After you start a session, you will keep adding image frames
    // until you are complete - then you will tell it you are done.
    [videoWriter startWriting];
    // This starts your video at time = 0
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    
    NSLog(@"    NSMutableArray *cgImages = [NSMutableArray new];");
    int i = 0;
    while (1) {
        // Check if the writer is ready for more data, if not, just wait
        if(writerInput.readyForMoreMediaData){
            NSLog(@"writerInput.readyForMoreMediaData) %i", i);
            
            CMTime frameTime = CMTimeMake(20, 600);
            // CMTime = Value and Timescale.
            // Timescale = the number of tics per second you want
            // Value is the number of tics
            // For us - each frame we add will be 1/4th of a second
            // Apple recommend 600 tics per second for video because it is a
            // multiple of the standard video rates 24, 30, 60 fps etc.
            CMTime lastTime=CMTimeMake(i*20, 600);
            CMTime presentTime=CMTimeAdd(lastTime, frameTime);
            
            if (i == 0) {presentTime = CMTimeMake(0, 600);}
            // This ensures the first frame starts at 0.
            
            
            if (i >= [array count])
            {
                buffer = NULL;
            } else {
                // This command grabs the next UIImage and converts it to a CGImage
                buffer = [self pixelBufferFromCGImage:([[array objectAtIndex:i] CGImage])];
            }
            
            
            if (buffer) {
                // Give the CGImage to the AVAssetWriter to add to your video
                [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                
                // release the buffer!!!!!!!!!!!!!!!!
                CVPixelBufferRelease(buffer);
                
                i++;
            } else {
                NSLog(@"Finish the session:");
                
                //Finish the session:
                // This is important to be done exactly in this order
                [writerInput markAsFinished];
                // WARNING: finishWriting in the solution above is deprecated.
                // You now need to give a completion handler.
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"Finished writing...checking completion status...");
                    if (videoWriter.status != AVAssetWriterStatusFailed && videoWriter.status == AVAssetWriterStatusCompleted)
                    {
                        NSLog(@"Video writing succeeded.");
                        
                        // Move video to camera roll
                        // NOTE: You cannot write directly to the camera roll.
                        // You must first write to an iOS directory then move it!
                        NSURL *videoTempURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@", path]];
                        [self saveToCameraRoll:videoTempURL];
//                        NSLog(@"Delay to write by 5 seconds");
//                        [self performSelector:@selector(saveToCameraRoll:) withObject:videoTempURL afterDelay:5.0f];
                        
                    } else
                    {
                        NSLog(@"Video writing failed: %@", videoWriter.error);
                    }
                    
                }]; // end videoWriter finishWriting Block
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                
                NSLog (@"Done");
                break;
            }
        }
    }    
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    // This again was just our utility class for the height & width of the
    // incoming video (640 height x 480 width)
    int height = [[VRDataManager sharedManager] exportingFrameSize].height;
    int width = [[VRDataManager sharedManager] exportingFrameSize].width;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 width,
                                                 height,
                                                 8,
                                                 4*width,
                                                 rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void) saveToCameraRoll:(NSURL *)srcURL {
    NSLog(@"srcURL: %@", srcURL);
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock =
    ^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image with metadata to Photo Library %@", newURL.absoluteString);
        }
    };
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:srcURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:srcURL
                                    completionBlock:videoWriteCompletionBlock];
    }
}



@end
