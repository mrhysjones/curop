//
//  ViewController.m
//  FaceTracker
//
//  Created by Matthew Jones on 04/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import "ViewController.h"
#import <mach/mach_time.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize videoView;
@synthesize toolbar;
@synthesize initialiseVideoButton;
@synthesize videoCamera;

- (void)viewDidLoad {
    [super viewDidLoad];
    prevTime = mach_absolute_time();
    
    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:videoView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
    AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation =
    AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    
    self.tracker = [[trackerWrapper alloc] init];
    [self.tracker initialiseModel];
    [self.tracker initialiseValues];

}

// Converts measured time to seconds for display
static double machTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e9;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [videoCamera stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Initialise the camera on button press
- (IBAction)initialiseVideo:(id)sender {
    [videoCamera start];
}

// Change between front/back camera on button press
- (IBAction)switchCamera:(id)sender {
    [videoCamera switchCameras];
}

- (IBAction)faceTrack:(id)sender {
    // Want to control which facial points you see - connections/triangles/points
}


- (IBAction)selectEmotion:(id)sender {
    // Ideally want a means of controlling which predictions you see
}

- (IBAction)settings:(id)sender {
    // Show FPS, white balance, exposure...
}

- (void)processImage:(cv::Mat&)image
{
    // Face tracking and emotion classification
    [self.tracker trackWithCvMat:image];
    
    
    // Add FPS to the image view
    uint64_t currTime = mach_absolute_time();
    double timeInSeconds = machTimeToSecs(currTime - prevTime);
    prevTime = currTime;
    double fps = 1.0 / timeInSeconds;
    NSString* fpsString =
    [NSString stringWithFormat:@"FPS = %3.2f",
     fps];
    cv::putText(image, [fpsString UTF8String],
                cv::Point(30, 30), cv::FONT_HERSHEY_COMPLEX_SMALL,
                0.8, cv::Scalar::all(0));
    
}

@end
