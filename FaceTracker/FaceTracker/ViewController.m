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
    
    // SVM tracker utilisation
    self.svm = [[svmWrapper alloc] init];
    
}

// Programmatic way of ensuring the status bar is hidden
- (BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)viewDidDisappear:(BOOL)animated
{
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

// Method that toggles classification (needs more appropriate name)
- (IBAction)selectEmotion:(id)sender {
    [self.tracker classify];
}

- (IBAction)settings:(id)sender {
    /*
     To be completed - table view that will allow you to toggle 
     which tracking points to draw, the FPS label, and which emotions 
     to output to the screen
     */
}

// Attempts to find the front camera on the device
- (AVCaptureDevice *) findFrontCamera
{
    AVCaptureDevice *frontCamera = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *currentDevice in devices) {
        if ([currentDevice hasMediaType:AVMediaTypeVideo]) {
            if ([currentDevice position] == AVCaptureDevicePositionFront) {
                frontCamera =  currentDevice;
            }
        }
        
    }
    return frontCamera;
}

// Sets up the capture, and starts the running of tracking
- (void) createAndRunNewSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.device = [self findFrontCamera];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    self.output = [[AVCaptureVideoDataOutput alloc] init];
    self.output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt: kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    self.output.alwaysDiscardsLateVideoFrames = YES;

    dispatch_queue_t queue;
    queue = dispatch_queue_create("new_queue", NULL);
    
    [self.output setSampleBufferDelegate:self queue:queue];
    
    // These checks have been put in place to stop simulator errors
    if ([self.session canAddInput:self.input]){
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output]){
        [self.session addOutput:self.output];
    }
    // Triggers captureOutput below
    [self.session startRunning];
}

// Function that does the processing of the samples
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
