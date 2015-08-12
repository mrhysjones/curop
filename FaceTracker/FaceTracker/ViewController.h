//
//  ViewController.h
//  FaceTracker
//
//  Created by Matthew Jones on 04/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgproc.hpp>
#import "trackerWrapper.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    CvVideoCamera* videoCamera;
    struct svm_model* svmmodel;
}


@property (weak, nonatomic) IBOutlet UIImageView *videoView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) trackerWrapper *tracker;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) CIContext *ciContext;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *initialiseVideoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showTrackingButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectEmotionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;


- (IBAction)initialiseVideo:(id)sender;
- (IBAction)faceTrack:(id)sender;
- (IBAction)selectEmotion:(id)sender;
- (IBAction)settings:(id)sender;


@end

