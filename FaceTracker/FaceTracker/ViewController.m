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
@synthesize options;


AVCaptureDevicePosition pos = AVCaptureDevicePositionFront;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Face tracker initialisation
    self.tracker = [[trackerWrapper alloc] init];
    [self.tracker initialiseModel];
    [self.tracker initialiseValues];
    
    // Initialise capture and video view
    [self createAndRunNewSession];
    
    // Load in user settings to the settings singleton
    [self loadUserSettings];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    // Added in to hide the navigation bar on the main camera view
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    if (options == 1){
        NSLog(@"Hey there");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    // Added in to unhide the navigation bar when moving away from camera view
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*! 
 @brief Set up the capture session and video view
 
 @discussion This method will cause the front camera to be used, and to display the output on a view 
 */
- (IBAction)switchCamera:(id)sender {
    if (pos == AVCaptureDevicePositionFront){
        pos = AVCaptureDevicePositionBack;
    }
    else{
        pos = AVCaptureDevicePositionFront;
    }
    [self createAndRunNewSession];
}

/*! 
 @brief Resets the face tracking on button press
 
 @discussion This method will allow a user to manually reset the face tracking. It calls the same method that is automatically used when the tracker fails
 */
- (IBAction)faceTrack:(id)sender {
    [self.tracker resetModel];
}

/*!
 @brief Toggles emotion classification on button press
 
 @discussion This method will call the 'classify' method in the trackerWrapper file, and will set the boolean value that controls classification to the opposite of what it currently is
 */
- (IBAction)toggleClassify:(id)sender {
    [self.tracker classify];
}

- (IBAction)settings:(id)sender {

    [self performSegueWithIdentifier:@"goSettings" sender:self];
}

/*! 
 @brief Finds the front/back camera from the available devices
 
 @discussion This method is called to look for all available capture devices, and to find the camera with specified position
 
 @return AVCaptureDevice    Camera if found, nil otherwise
 */
- (AVCaptureDevice *) findCamera:(AVCaptureDevicePosition) pos
{
    AVCaptureDevice *camera = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *currentDevice in devices) {
        if ([currentDevice hasMediaType:AVMediaTypeVideo]) {
            if ([currentDevice position] == pos) {
                camera =  currentDevice;
            }
        }
    }
    return camera;
}



-(void) loadUserSettings
{
    // Ensure that singleton updates from stored user values 
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    
    [[SettingsSingleton sharedMySingleton] toggleFPS:[d boolForKey:@"fpsValue"]];
     
    [[SettingsSingleton sharedMySingleton] togglePoints:[d boolForKey:@"pointsValue"]];
    
    [[SettingsSingleton sharedMySingleton] toggleConnections:[d boolForKey:@"connectionValue"]];
    
    [[SettingsSingleton sharedMySingleton] toggleTriangulation:[d boolForKey:@"triangulationValue"]];
}



/*!
 @brief Sets up the input/output required for the app to work 
 
 @discussion This method is used to set up a capture session with the front camera, to set up the output video, and also to handle the video buffer 
 
 */
- (void) createAndRunNewSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.device = [self findCamera:pos];
    
    
    if ([self.device lockForConfiguration:nil]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        [self.device unlockForConfiguration];
    }
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

/*!
 @brief Applies processsing to the output from the camera
 
 @discussion This method will take a sample from the buffer, and will apply the tracking methods to this sample, before adding the resultant image to the video view
 */
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
