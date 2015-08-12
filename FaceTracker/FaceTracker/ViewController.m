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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Face tracker initialisation
    self.tracker = [[trackerWrapper alloc] init];
    [self.tracker initialiseModel];
    [self.tracker initialiseValues];
    
}



// Programmatic way of ensuring the status bar hidden
- (BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)viewDidDisappear:(BOOL)animated
{
    [videoCamera stop];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Initialise the camera on button press
- (IBAction)initialiseVideo:(id)sender {
    [self createAndRunNewSession];
}

// Method that resets the tracker if it's not picking up face correctly
- (IBAction)faceTrack:(id)sender {
    [self.tracker resetModel];
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

}


#pragma mark - AVFoundationCode
- (AVCaptureDevice *) findFrontCamera
{
    AVCaptureDevice *frontCamera = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *currentDevice in devices) {
        NSLog(@"%@", currentDevice);
        if ([currentDevice hasMediaType:AVMediaTypeVideo]) {
            if ([currentDevice position] == AVCaptureDevicePositionFront) {
                
                frontCamera =  currentDevice;
            }
            
        }
        
    }
    return frontCamera;
}

- (void) createAndRunNewSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.device = [self findFrontCamera];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    self.output = [[AVCaptureVideoDataOutput alloc] init];
    self.output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt: kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    self.output.alwaysDiscardsLateVideoFrames = YES;

    dispatch_queue_t queue;
    queue = dispatch_queue_create("new_queue", NULL);
    
    [self.output setSampleBufferDelegate:self queue:queue];
    
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    [self.session startRunning];
    
    
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // start tracking data and get image of tracked face
        UIImage *trackedImage = [self.tracker trackWithCVImageBufferRef:imageBuffer];

        // Show modified image on video view
        [self.videoView performSelectorOnMainThread:@selector(setImage:) withObject:trackedImage waitUntilDone:YES];

    }
}



@end
