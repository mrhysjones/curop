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

@interface ViewController : UIViewController<CvVideoCameraDelegate>
{
    CvVideoCamera* videoCamera;
    uint64_t prevTime;
}

@property (nonatomic, strong) CvVideoCamera* videoCamera;

@property (weak, nonatomic) IBOutlet UIImageView *videoView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) trackerWrapper *tracker;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *initialiseVideoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showTrackingButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectEmotionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;


- (IBAction)initialiseVideo:(id)sender;
- (IBAction)switchCamera:(id)sender;
- (IBAction)faceTrack:(id)sender;
- (IBAction)selectEmotion:(id)sender;
- (IBAction)settings:(id)sender;


@end

