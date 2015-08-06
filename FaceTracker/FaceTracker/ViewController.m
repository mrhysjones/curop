//
//  ViewController.m
//  FaceTracker
//
//  Created by Matthew Jones on 04/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize videoView;
@synthesize toolbar;
@synthesize initialiseVideoButton;
@synthesize videoCamera;

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
}

- (IBAction)selectEmotion:(id)sender {

}

- (IBAction)settings:(id)sender {
    // Show FPS, white balance, exposure on a different screen..
}

- (void)processImage:(cv::Mat&)image
{
    self.tracker = [[trackerWrapper alloc] init];
    [self.tracker initialiseModel];
    [self.tracker initialiseValues];
    [self.tracker trackWithCvMat:image];
    
}









@end
