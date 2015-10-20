//
//  ViewController.m
//  360 Video Text
//
//  Created by Nathan Fennel on 10/17/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VRBackgroundFrame.h"
#import "VRExportVideo.h"
#import "VRDataManager.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView *vImagePreview;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) CMDeviceMotion *deviceMotion;

@property (nonatomic, strong) UILabel *lbl_pitch, *lbl_yaw, *lbl_roll, *lbl_isvalid;

@property (nonatomic, strong) UIButton *exportButton, *recordButton, *dismissButton;

@property (nonatomic, strong) ALAssetsLibrary *library;

@property (nonatomic, strong) NSMutableArray *images, *tempImageViews;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) AVCaptureSession *AVSession;

@end


@implementation ViewController {
    float pre_yaw;
    float xpost;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    AVCaptureVideoDataOutput *frameOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    CGFloat currentBackgroundFramePitchInDegrees;
    CGFloat currentBackgroundFrameRollInDegrees;
    CGFloat currentBackgroundFrameYawInDegrees;
    int compositedRange;
    NSMutableArray *finalImageSequence;
    UIImageView *videoFrame;
    BOOL receivedMemoryWarning, exporting;
    CGSize exportVImagePreviewSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.totalFrame];
    self.view.backgroundColor = [UIColor darkGrayColor];
    [self motionManager];
    
    [self start];
    [self.totalFrame addSubview:self.compositeBackgroundView];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.0083 target:self selector:@selector(doSomething) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.12 target:self selector:@selector(updateBackgroundImageView) userInfo:nil repeats:YES];
    
    [self.view addSubview:self.lbl_pitch];
    [self.view addSubview:self.lbl_roll];
    [self.view addSubview:self.lbl_yaw];
	[self.view addSubview:self.lbl_isvalid];
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.exportButton];
    [self.view addSubview:self.dismissButton];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    self.totalFrame.frame = [self totalFrameFrame];
    self.totalFrame.center = self.view.center;
}

- (UIView *)totalFrame {
    if (!_totalFrame) {
        _totalFrame = [[UIView alloc] initWithFrame:[self totalFrameFrame]];
        _totalFrame.center = self.view.center;
        _totalFrame.backgroundColor = [UIColor blackColor];
//        _totalFrame.layer.borderColor = [UIColor lightGrayColor].CGColor;
//        _totalFrame.layer.borderWidth = 2.0f;
        _totalFrame.clipsToBounds = YES;
        [_totalFrame addSubview:self.compositeBackgroundView];
    }
    
    return _totalFrame;
}

- (UIView *)vImagePreview {
    if (!_vImagePreview) {
        _vImagePreview = [[UIView alloc] initWithFrame:[self vImagePreviewFrame]];
        _vImagePreview.center = CGPointMake(self.totalFrame.bounds.size.width * 0.5f, self.totalFrame.bounds.size.height * 0.5f);
//        _vImagePreview.layer.borderColor = [UIColor blueColor].CGColor;
//        _vImagePreview.layer.borderWidth = 5.0f;
        _vImagePreview.contentMode = UIViewContentModeScaleToFill;
//		_vImagePreview.hidden = YES;
    }
    
    return _vImagePreview;
}

- (CGRect)vImagePreviewFrame {
    CGRect refFrame = [self totalFrameFrame];
    CGRect frame = CGRectMake(0.0f, 0.0f, refFrame.size.width * [VRDataManager exportingRatio], refFrame.size.width * [VRDataManager exportingRatio]);
    
    return frame;
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager startDeviceMotionUpdates];
    }
    
    return _motionManager;
}

- (CGRect)totalFrameFrame {
    CGRect frame = self.view.bounds;
    
    if (exporting) {
        frame.size.width = [VRDataManager exportingFrameSize].width * 0.5f;//frame.size.height * 2.0f;
        frame.size.height = [VRDataManager exportingFrameSize].height * 0.5f;
    }
    
    return frame;
}

- (void)start {
    self.AVSession = [[AVCaptureSession alloc] init];

    if ([self.AVSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.AVSession.sessionPreset = AVCaptureSessionPreset640x480;
    } else if ([self.AVSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        self.AVSession.sessionPreset = AVCaptureSessionPreset352x288;
    } else {
        NSLog(@"Low isn't working too well");
        self.AVSession.sessionPreset = AVCaptureSessionPresetLow;
    }
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *capInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (capInput) [self.AVSession addInput:capInput];
    
    for(AVCaptureDeviceFormat *vFormat in [videoDevice formats] )
    {
        CMFormatDescriptionRef description= vFormat.formatDescription;
        float maxrate=((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        
        if(maxrate>59 && CMFormatDescriptionGetMediaSubType(description)==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        {
            if ( YES == [videoDevice lockForConfiguration:NULL] )
            {
                videoDevice.activeFormat = vFormat;
                [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(20,600)];
                [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(20,600)];
                [videoDevice unlockForConfiguration];
                NSLog(@"formats  %@ %@ %@",vFormat.mediaType,vFormat.formatDescription,vFormat.videoSupportedFrameRateRanges);
            }
        }
    }
    
    captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.AVSession];
    
    self.images = [[NSMutableArray alloc] init];
    
    captureVideoPreviewLayer.frame = self.vImagePreview.bounds;
    captureVideoPreviewLayer.orientation = UIInterfaceOrientationLandscapeRight;
    
    [self.vImagePreview.layer addSublayer:captureVideoPreviewLayer];
    
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
    [videoOut setSampleBufferDelegate:self queue:videoQueue];
    videoOut.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    videoOut.alwaysDiscardsLateVideoFrames=YES;
    
    if (videoOut)
    {
        [self.AVSession addOutput:videoOut];
        self.videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    }
    
    [self.AVSession startRunning];
}

- (UILabel *)lbl_pitch {
    if (!_lbl_pitch) {
        _lbl_pitch = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - 120.0f, 60.0f, 44.0f)];
        _lbl_pitch.backgroundColor = [UIColor whiteColor];
        _lbl_pitch.alpha = 0.5f;
    }
    
    return _lbl_pitch;
}

- (UILabel *)lbl_yaw {
    if (!_lbl_yaw) {
        _lbl_yaw = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - 164.0f, 60.0f, 44.0f)];
        _lbl_yaw.backgroundColor = [UIColor whiteColor];
        _lbl_yaw.alpha = 0.5f;
    }
    
    return _lbl_yaw;
}

- (UILabel *)lbl_roll {
    if (!_lbl_roll) {
        _lbl_roll = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - 208.0f, 60.0f, 44.0f)];
        _lbl_roll.backgroundColor = [UIColor whiteColor];
        _lbl_roll.alpha = 0.5f;
    }
    
    return _lbl_roll;
}

- (UILabel *)lbl_isvalid {
    if (!_lbl_isvalid) {
        _lbl_isvalid = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - 252.0f, 60.0f, 44.0f)];
        _lbl_isvalid.backgroundColor = [UIColor whiteColor];
        _lbl_isvalid.alpha = 0.5f;
    }
    
    return _lbl_isvalid;
}

- (UIButton *)exportButton {
    if (!_exportButton) {
        _exportButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 60, self.view.bounds.size.height - 60, 44.0f, 44.0f)];
        _exportButton.backgroundColor = [UIColor redColor];
        _exportButton.layer.cornerRadius = 22.0f;
        _exportButton.clipsToBounds = YES;
        [_exportButton addTarget:self action:@selector(exportButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [_exportButton setTitle:@"e" forState:UIControlStateNormal];
    }
    
    return _exportButton;
}

- (void)exportButtonTouched:(UIButton *)exportButton {
    if (exporting) {
        NSLog(@"Already Exporting");
        return;
    } else {
        exporting = YES;
    }
    
    [self.AVSession stopRunning];
    
    [self performSelector:@selector(export) withObject:self afterDelay:1.0f]; // pause to make sure images are not still being saved
    self.vImagePreview.hidden = YES;
    
    CGRect refFrame = [self totalFrameFrame];
    
    if (exporting) {
        exportVImagePreviewSize = CGSizeMake(refFrame.size.width * [VRDataManager exportingRatio],
                                             refFrame.size.width * [VRDataManager exportingRatio]);
    }
}

- (void)export {
    self.compositeBackgroundView.frame = [self totalFrameFrame];
    self.backgroundImageView.frame = [self totalFrameFrame];
    self.totalFrame.frame = [self totalFrameFrame];
    self.totalFrame.center = self.view.center;
    
    if (finalImageSequence) {
        [finalImageSequence removeAllObjects];
    }
    
    finalImageSequence = [NSMutableArray new];
    if (!videoFrame) {
        videoFrame = [[UIImageView alloc] initWithFrame:CGRectZero];
        videoFrame.contentMode = UIViewContentModeScaleToFill;
    }
    
    [self.compositeBackgroundView addSubview:videoFrame];
    
    [self saveNextFrame:@0];
}

- (void)saveNextFrame:(NSNumber *)frameNumber {
    int numberOfImagesPerBatch = [VRDataManager numberOfImagesPerBatch];
    
    if (frameNumber.intValue < self.images.count && !receivedMemoryWarning && finalImageSequence.count < numberOfImagesPerBatch) {
        NSLog(@"Frame %@/%zd", frameNumber, self.images.count - 1);
        VRBackgroundFrame *backgroundFrame = [self.images objectAtIndex:frameNumber.intValue];
        videoFrame.image = backgroundFrame.image;
        [self updateVImagePreviewFrameWithYaw:backgroundFrame.yawInDegrees
                                         roll:backgroundFrame.rollInDegrees
                                        pitch:backgroundFrame.pitchInDegrees];
        CGRect frame = self.vImagePreview.frame;
        float cosine = fabs(sinf((backgroundFrame.rollInDegrees + 90) / 180 * M_PI)) + 1.0f;
        frame.size.width = exportVImagePreviewSize.width * cosine;
        frame.size.height = exportVImagePreviewSize.height;
        videoFrame.frame = frame;
        videoFrame.contentMode = UIViewContentModeScaleToFill;
        UIImage *compositeImage = [self imageWithView:self.compositeBackgroundView];
		videoFrame.transform = CGAffineTransformMakeRotation((backgroundFrame.pitchInDegrees - 0)* M_PI/180);
        [finalImageSequence addObject:compositeImage];
        [self performSelector:@selector(saveNextFrame:)
                   withObject:[NSNumber numberWithInt:frameNumber.intValue + 1]
                   afterDelay:0.05f];
    } else {
        NSMutableArray *partialImageSequences = [NSMutableArray new];
        
        for (int i = 0; i < finalImageSequence.count; i++) {
            NSMutableArray *sequence = [NSMutableArray new];
            
            for (int currentImage = i, relativeCount = 0; relativeCount < numberOfImagesPerBatch && currentImage < finalImageSequence.count; currentImage++, i++, relativeCount++) {
                [sequence addObject:[finalImageSequence objectAtIndex:currentImage]];
            }
            [partialImageSequences addObject:sequence];
        }
        
        // flip to show in correct order
        NSArray *reversed = [[partialImageSequences reverseObjectEnumerator] allObjects];
        for (int t = 0, i = 0; i < reversed.count; t+=2, i++) {
            NSArray *sequence = [reversed objectAtIndex:i];
            [self performSelector:@selector(convertImagesToMovie:) withObject:sequence afterDelay:t];
        }
        
        [finalImageSequence removeAllObjects];
		[self.images removeAllObjects];
        
        if (reversed.count > 0) {
            [self performSelector:@selector(saveNextFrame:)
                       withObject:[NSNumber numberWithInt:frameNumber.intValue + 1]
                       afterDelay:3.05f];
        } else {
            [self performSelector:@selector(dismissButtonTouched:) withObject:self.dismissButton afterDelay:5.0f];
        }
    }
}

- (void)convertImagesToMovie:(NSArray *)imageSequence {
    NSLog(@"Converting again!");
    [[[VRExportVideo alloc] init] saveMovieToLibrary:imageSequence];
}

- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 60, 20.0f, 44.0f, 44.0f)];
        _recordButton.backgroundColor = [UIColor redColor];
        _recordButton.layer.cornerRadius = 22.0f;
        _recordButton.clipsToBounds = YES;
        [_recordButton addTarget:self action:@selector(recordButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _recordButton;
}

- (void)recordButtonTouched:(UIButton *)button {
    if (!self.tempImageViews) {
        self.tempImageViews = [NSMutableArray new];
    }
    
    if (exporting) {
        return;
    }
    
    
    
    NSMutableArray *copiedArray = [NSMutableArray new];
    
    for (int i = compositedRange; i < self.images.count; i+= 3) {
        [copiedArray addObject:[self.images objectAtIndex:i]];
        compositedRange = i;
    }
    
    for (VRBackgroundFrame *backgroundFrame in copiedArray) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:backgroundFrame.image];
        imageView.frame = [self vImagePreviewFrame];
        imageView.center = CGPointMake([self totalFrameFrame].size.width - [self ratioAroundYaw:backgroundFrame.yawInDegrees] * [self totalFrameFrame].size.width, [self ratioAroundRoll:backgroundFrame.rollInDegrees] * [self totalFrameFrame].size.height);
        imageView.transform = CGAffineTransformMakeRotation((backgroundFrame.pitchInDegrees - 0 )* M_PI/180);
//        CALayer *layer = imageView.layer;
//        CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
//        rotationAndPerspectiveTransform.m34 = 1.0 / -500;
//        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, 0.0f, backgroundFrame.pitchInDegrees * M_PI / 180.0f, 1.0f, 0.0f);
//        layer.transform = rotationAndPerspectiveTransform;

        [self.tempImageViews addObject:imageView];
    }
    
    for (UIImageView *imageView in self.tempImageViews) {
        [self.compositeBackgroundView addSubview:imageView];
    }
    
    self.backgroundImageView.image = [self imageWithView:self.compositeBackgroundView];
    
    for (UIImageView *imageView in self.tempImageViews) {
        [imageView removeFromSuperview];
    }
    
    [self.tempImageViews removeAllObjects];
}

- (void)doSomething {
    _deviceMotion = [self.motionManager deviceMotion];
    
    float fyaw=_deviceMotion.attitude.yaw     * 180 / M_PI;
    float fpitch=_deviceMotion.attitude.pitch * 180 / M_PI;
    float froll=_deviceMotion.attitude.roll   * 180 / M_PI;
    
    self.lbl_pitch.text = [ NSString stringWithFormat:@"P: %.0f",fpitch];
    self.lbl_yaw.text   = [ NSString stringWithFormat:@"Y: %.0f",fyaw];
    self.lbl_roll.text  = [ NSString stringWithFormat:@"R: %.0f",froll];
	
	float cosine = fabs(sinf((froll + 90) / 180 * M_PI)) + 1.0f;
	self.lbl_isvalid.text = [ NSString stringWithFormat:@"C: %.0f",cosine];
    CGRect frame = [self vImagePreviewFrame];
    frame.size.width *= cosine;
    self.vImagePreview.frame = frame;
    self.vImagePreview.center = CGPointMake([self totalFrameFrame].size.width - [self ratioAroundYaw:fyaw] * [self totalFrameFrame].size.width, [self ratioAroundRoll:froll] * [self totalFrameFrame].size.height);
    self.vImagePreview.transform = CGAffineTransformMakeRotation(fpitch * M_PI/180);
    
    currentBackgroundFramePitchInDegrees = fpitch;
    currentBackgroundFrameRollInDegrees = froll;
    currentBackgroundFrameYawInDegrees = fyaw;
    
    pre_yaw=fyaw;
}

- (void)updateVImagePreviewFrameWithYaw:(float)fyaw roll:(float)froll pitch:(float)fpitch {
    self.vImagePreview.frame = [self vImagePreviewFrame];
    self.vImagePreview.center = CGPointMake([self totalFrameFrame].size.width - [self ratioAroundYaw:fyaw] * [self totalFrameFrame].size.width, [self ratioAroundRoll:froll] * [self totalFrameFrame].size.height);
    self.vImagePreview.transform = CGAffineTransformMakeRotation(fpitch * M_PI/180);
    
}

- (void)updateBackgroundImageView {
    [self.backgroundImageView setImage:[self imageWithView:self.compositeBackgroundView]];
    
    [self recordButtonTouched:nil];
}

- (UIView *)compositeBackgroundView {
    if (!_compositeBackgroundView) {
        _compositeBackgroundView = [[UIView alloc] initWithFrame:[self totalFrameFrame]];
        [_compositeBackgroundView addSubview:self.backgroundImageView];
        [_compositeBackgroundView addSubview:self.vImagePreview];
    }
    
    return _compositeBackgroundView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:[self totalFrameFrame]];
//        _backgroundImageView.layer.borderColor = [UIColor redColor].CGColor;
//        _backgroundImageView.layer.borderWidth = 6.0f;
    }
    
    return _backgroundImageView;
}

- (float)ratioAroundYaw:(float)yaw {
    float workingValue = yaw + 180;
    
    workingValue /= 360.0f;
    
    return workingValue;
}

- (float)ratioAroundRoll:(float)roll {
    float workingValue = roll + 180;
    workingValue /= 180.0f;
    
    return workingValue;
}

- (UIImage *)imageWithLayer:(AVCaptureVideoPreviewLayer *)layer {
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, 0.0);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)saveImage:(UIImage *)image {
    if (!self.library) {
        self.library = [[ALAssetsLibrary alloc] init];
    }
    
    __weak ALAssetsLibrary *lib = self.library;
    
    [self.library addAssetsGroupAlbumWithName:@"360 Photos" resultBlock:^(ALAssetsGroup *group) {
        ///checks if group previously created
        if(group == nil){
            
            //enumerate albums
            [lib enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *g, BOOL *stop)
             {
                 
                 //if the album is equal to our album
                 if ([[g valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"360 Photos"]) {
                     
                     //save image
                     [lib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(image) metadata:nil
                                           completionBlock:^(NSURL *assetURL, NSError *error) {
                                               
                                               //then get the image asseturl
                                               [lib assetForURL:assetURL
                                                    resultBlock:^(ALAsset *asset) {
                                                        //put it into our album
                                                        [g addAsset:asset];
                                                    } failureBlock:^(NSError *error) {
                                                        
                                                    }];
                                           }];
                     
                 }
             }failureBlock:^(NSError *error){
                 
             }];
            
        }else{
            // save image directly to library
            [lib writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(image) metadata:nil
                                  completionBlock:^(NSURL *assetURL, NSError *error) {
                                      
                                      [lib assetForURL:assetURL
                                           resultBlock:^(ALAsset *asset) {
                                               
                                               [group addAsset:asset];
                                               
                                           } failureBlock:^(NSError *error) {
                                               
                                           }];
                                  }];
        }
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection{
    
    if (exporting) {
        return;
    }
    
    
    // Create a UIImage from the sample buffer data
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    VRBackgroundFrame *backgroundFrame = [VRBackgroundFrame new];
	
	CGSize scaledSize = [self vImagePreviewFrame].size;
	
	if (scaledSize.width < 128) {
		scaledSize = CGSizeMake(128.0f, 128.0f);
	}
	
    backgroundFrame.image = [self imageWithImage:image scaledToSize:scaledSize];
    NSLog(@"Image is: %g x %g", backgroundFrame.image.size.width, backgroundFrame.image.size.height);
    backgroundFrame.pitchInDegrees = currentBackgroundFramePitchInDegrees;
    backgroundFrame.rollInDegrees = currentBackgroundFrameRollInDegrees;
    backgroundFrame.yawInDegrees = currentBackgroundFrameYawInDegrees;
//    backgroundFrame.frame = currentBackgroundFrame;
//    backgroundFrame.pitchInDegrees = currentBackgroundFramePitchInDegrees;
    [self.images addObject:backgroundFrame];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


-(void) captureNow {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    NSLog(@"about to request a capture from: %@", stillImageOutput);
    __weak typeof(self) weakSelf = self;
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (error) {
            NSLog(@"imageSampleBuffer Error: %@", error);
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        NSLog(@"Nothing will happen here either...same thing as before");
//        VRBackgroundFrame *backgroundFrame = [VRBackgroundFrame new];
//        backgroundFrame.image = image;
//        backgroundFrame.frame = currentBackgroundFrame;
//        backgroundFrame.pitchInDegrees = currentBackgroundFramePitchInDegrees;
//        [self.images addObject:backgroundFrame];
    }];
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
        [_dismissButton setTitle:@"Done" forState:UIControlStateNormal];
        _dismissButton.backgroundColor = [UIColor blueColor];
        [_dismissButton addTarget:self action:@selector(dismissButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _dismissButton;
}

- (void)dismissButtonTouched:(UIButton *)button {
	[self.AVSession stopRunning];
	
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"Received Memory Warning");
    
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
    
    receivedMemoryWarning = YES;
}

@end
