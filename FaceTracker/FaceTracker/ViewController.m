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

- (IBAction)initialiseVideo:(id)sender {
    [videoCamera start];
}

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
    cv::Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
}


void Draw(cv::Mat &image, cv::Mat &shape, cv::Mat &con, cv::Mat &tri,
          cv::Mat &visi, cv::Mat &rshape) {
    int i, n = shape.rows / 2;
    cv::Point p1, p2;
    cv::Scalar c;
    
    // draw rect shape
    for (i = 0; i < n; i++) {
        if (visi.at<int>(i, 0) == 0)
            continue;
        p1 = cv::Point(rshape.at<double>(i, 0), rshape.at<double>(i + n, 0));
        c = CV_RGB(0,255,0);
        cv::circle(image, p1, 2, c);
        cv::putText(image, std::to_string(i+1),p1,CV_FONT_HERSHEY_PLAIN,0.5,cv::Scalar::all(0));
    } 
    
    //draw points
    for (i = 0; i < n; i++) {
        if (visi.at<int>(i, 0) == 0)
            continue;
        p1 = cv::Point(shape.at<double>(i, 0), shape.at<double>(i + n, 0));
        c = CV_RGB(255,0,0);
        cv::circle(image, p1, 2, c);
        cv::putText(image, std::to_string(i+1),p1,CV_FONT_HERSHEY_PLAIN,0.5,cv::Scalar::all(0));
    }
    return;
    
}



@end
