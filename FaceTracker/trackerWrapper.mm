//
//  trackerWrapper.m
//  iOSFaceTracker 2
//
//  Created by Tom Hartley on 01/12/2012.
//  Copyright (c) 2012 Tom Hartley. All rights reserved.
//

#import "trackerWrapper.h"




@implementation trackerWrapper {
    int switchVal;
    
    
    
    
    FACETRACKER::Tracker model;
    cv::Mat tri;
    cv::Mat con;
    
    
    
    
    std::vector<int> wSize1;
    std::vector<int> wSize2;
    std::vector<int> wSize;
    
    
    bool fcheck;
    double scale;
    int fpd;
    bool show;
    
    int nIter;
    double clamp,fTol;
    
    
    cv::Mat gray,im;
    
    bool failed;
    
    imageConversion *imageConverter;
    
    
}






-(void)initialiseModel
{
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"face2" ofType:@"tracker"];
    NSString *triPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"tri"];
    NSString *conPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"con"];
    
    
    
    const char *modelPathString = [modelPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *triPathString = [triPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *conPathString = [conPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    
    
    model.Load(modelPathString);
    tri=FACETRACKER::IO::LoadTri(triPathString);
    con=FACETRACKER::IO::LoadCon(conPathString);
    
    imageConverter = [[imageConversion alloc] init];
    
}


-(void)initialiseValues
{
    wSize1.resize(1);
    wSize2.resize(3);
    wSize1[0] = 7;
    wSize2[0] = 11;
    wSize2[1] = 9;
    wSize2[2] = 7;
    
    fcheck = false;
    scale = 1;
    fpd = -1;
    show = true;
    nIter = 15;//5
    clamp=3;
    fTol=0.01;
    failed = true;
    
    
    
}





-(void) draw
{
    cv::Mat shape = model._shape;
    cv::Mat visi = model._clm._visi[model._clm.GetViewIdx()];
    
    
    int i,n = shape.rows/2; cv::Point p1,p2; cv::Scalar c;
//    
    //draw triangulation
    c = CV_RGB(255,0,0);
    for(i = 0; i < tri.rows; i++){
        if(visi.at<int>(tri.at<int>(i,0),0) == 0 ||
           visi.at<int>(tri.at<int>(i,1),0) == 0 ||
           visi.at<int>(tri.at<int>(i,2),0) == 0)continue;
        p1 = cv::Point(shape.at<double>(tri.at<int>(i,0),0),
                       shape.at<double>(tri.at<int>(i,0)+n,0));
        p2 = cv::Point(shape.at<double>(tri.at<int>(i,1),0),
                       shape.at<double>(tri.at<int>(i,1)+n,0));
        cv::line(im,p1,p2,c);
        p1 = cv::Point(shape.at<double>(tri.at<int>(i,0),0),
                       shape.at<double>(tri.at<int>(i,0)+n,0));
        p2 = cv::Point(shape.at<double>(tri.at<int>(i,2),0),
                       shape.at<double>(tri.at<int>(i,2)+n,0));
        cv::line(im,p1,p2,c);
        p1 = cv::Point(shape.at<double>(tri.at<int>(i,2),0),
                       shape.at<double>(tri.at<int>(i,2)+n,0));
        p2 = cv::Point(shape.at<double>(tri.at<int>(i,1),0),
                       shape.at<double>(tri.at<int>(i,1)+n,0));
        cv::line(im,p1,p2,c);
    }
    //draw connections
    c = CV_RGB(255,0,0);
    for(i = 0; i < con.cols; i++){
        if(visi.at<int>(con.at<int>(0,i),0) == 0 ||
           visi.at<int>(con.at<int>(1,i),0) == 0)continue;
        p1 = cv::Point(shape.at<double>(con.at<int>(0,i),0),
                       shape.at<double>(con.at<int>(0,i)+n,0));
        p2 = cv::Point(shape.at<double>(con.at<int>(1,i),0),
                       shape.at<double>(con.at<int>(1,i)+n,0));
        cv::line(im,p1,p2,c,1);
    }
    
    //draw points
  
    for(i = 0; i < n; i++){
        if(visi.at<int>(i,0) == 0)continue;
        p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
        c = CV_RGB(0,255,0); cv::circle(im,p1,2,c);
        
    }
    
    
}

-(void)track
{
   
    if(failed) {
        wSize = wSize2;
    } else {
        wSize = wSize1;
    }
    
    if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0) {
        
        [self draw];
        failed = false;
        
    }else{
        
        [self resetModel];
        failed = true;
    }
    
}

-(void)resetModel
{
    model.FrameReset();
}

-(UIImage *)trackWithImage:(UIImage *)image
{
    static cv::Mat frame;
    frame = [imageConverter cvMatWithImage:image];
    
    if(scale == 1)im = frame;
    else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
    cv::flip(im,im,1);
    cv::cvtColor(im,gray,CV_BGR2GRAY);
    
    [self track];
    
    
    
    return [imageConverter UIImageFromMat:im];
    
}

-(UIImage *)trackWithCvMat:(cv::Mat)frame
{
    //frame =  image;
    
    if(scale == 1)im = frame;
    else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
    cv::flip(im,im,1);
    cv::cvtColor(im,gray,CV_BGR2GRAY);
    
    [self track];
    
    return [imageConverter UIImageFromMat:im];
    
}

-(UIImage *)trackWithCVImageBufferRef:(CVImageBufferRef)imageBuffer
{
    
    
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    //size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
    //NSLog(@"Frame captured: %lu x %lu", width,height);
    
    cv::Mat frame(height, width, CV_8UC4, (void*)baseAddress);
    
    // Make image the correct orientation for upwards iPad
    cv::Mat dst;
    cv::transpose(frame, dst);
    cv::flip(dst, dst, 1);
    
    // Convert from native BGRA to RGBA
    cvtColor(dst,frame,CV_BGRA2RGBA);
    
    
    if(scale == 1)im = frame;
    else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
    cv::flip(im,im,1);
    cv::cvtColor(im,gray,CV_BGR2GRAY);
    
    
    
    
    
    
    
    
    [self track];
    
    

    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    return [imageConverter UIImageFromMat:im];
    
}



- (NSMutableArray *)getRotation
{
    cv::Mat pose = model._clm._pglobl;
    
    NSMutableArray *rotationArray = [[NSMutableArray alloc] initWithCapacity:3];
    

    
    for (int i = 0; i<3; i++) {
        
        [rotationArray addObject:[NSNumber numberWithDouble:pose.at<double>(i, 0)]];
    }
    
    
    

    return rotationArray;
    
}

-(double)getScale {
	CvMat pose = model._clm._pglobl;
    //NSLog(@"%f",cvGetReal2D(&pose,0,0));
	return cvGetReal2D(&pose,0,0) ;
}


-(NSArray *) get3dMesh{
    static cv::Mat mesh;
    
    
    mesh.create(model._clm._pdm._M.rows,1,CV_64F);
    
    mesh = model._clm._pdm._M + model._clm._pdm._V*model._clm._plocal; // mean + variation * weights;
    
    int n = mesh.rows/3;
    
    NSMutableArray *meshArray = [[NSMutableArray alloc] initWithCapacity:n];
    
    
    
    for (int i = 0; i<n; i++) {
        
        NSNumber *x = [NSNumber numberWithDouble:mesh.at<double>(i, 0)];
        NSNumber *y = [NSNumber numberWithDouble:-(mesh.at<double>(i+n, 0))]; // Made negative to account for reverse y-axis in OpenGl
        NSNumber *z = [NSNumber numberWithDouble:(-mesh.at<double>(i+n+n, 0))];
        
        [meshArray addObject:@[x,y,z]];
    }
    
    //    static BOOL oneTimeTest = YES;
    //
    //    if(oneTimeTest) {
    //        for (NSArray* xyz in meshArray) {
    //            //NSLog(@"%@\n", xyz);
    //
    //            printf("{{%f,%f,%f}, {0.5,0.5,0.5,1}},\n", [[xyz objectAtIndex:0] doubleValue],[[xyz objectAtIndex:1] doubleValue],[[xyz objectAtIndex:2] doubleValue]);
    //
    //
    //        }
    //
    //        oneTimeTest = NO;
    //    }
    
    
    return meshArray;
}

-(NSArray *)getSpecificPoint:(int)point {
    
    //NSMutableArray *pointCoords = [[NSMutableArray alloc] init];
    static cv::Mat mesh;
    
    
    mesh.create(model._clm._pdm._M.rows,1,CV_64F);
    
    mesh = model._clm._pdm._M + model._clm._pdm._V*model._clm._plocal; // mean + variation * weights;
    
    int n = mesh.rows/3;
    
    NSNumber *x = [NSNumber numberWithDouble:mesh.at<double>(point, 0)];
    NSNumber *y = [NSNumber numberWithDouble:-(mesh.at<double>(point+n, 0))]; // Made negative to account for reverse y-axis in OpenGl
    NSNumber *z = [NSNumber numberWithDouble:(-mesh.at<double>(point+n+n, 0))];
    
    //[pointCoords addObject:@[x,y,z]];
    
    return @[x,y,z];
}


@end
