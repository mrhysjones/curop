//
//  trackerWrapper.m
//  iOSFaceTracker 2
//
//  Created by Tom Hartley on 01/12/2012.
//  Last Modified by Matthew Jones on 01/09/2015
//  Copyright (c) 2012 Tom Hartley. All rights reserved.
//

#import "trackerWrapper.h"
#import <mach/mach_time.h>

using namespace cv;


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
    
    uint64_t prevTime;
    
    int nIter;
    double clamp,fTol;
    
    cv::Mat gray,im;
    
    bool failed;
    
    imageConversion *imageConverter;
    svmWrapper* svm;

    bool classify;
    
    int eigsize;
    std::vector<double> test, feat, mu, sigma, eigv[18];
    NSString *trainPath, *trainRangePath, *muPath, *sigmaPath, *wtPath, *vectorPath, *fpsString, *vectorScalePath, *predictPath;
    NSArray *emotions;
    
}

// Loads in the face tracker and starts the image converter used on samples
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
    svm = [[svmWrapper alloc] init];
    
}

// Initialise values relating to the tracker and also the SVM classification
-(void)initialiseValues
{
    prevTime = mach_absolute_time();
    
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
    
    trainPath = [[NSBundle mainBundle] pathForResource:@"emotions.train.pca" ofType:@"model"];
    const char* trainPathString = [trainPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    trainRangePath = [[NSBundle mainBundle] pathForResource:@"emotions.train.pca" ofType:@"range"];
    
    wtPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_wt" ofType:@"txt"];
    const char *wtPathString = [wtPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    muPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_mu" ofType:@"txt"];
    const char *muPathString = [muPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    sigmaPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_sigma" ofType:@"txt"];
    const char *sigmaPathString = [sigmaPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    vectorPath = [[self applicationDocumentsDirectory].path
                                   stringByAppendingPathComponent:@"vector.pca"];
    
    vectorScalePath = [[self applicationDocumentsDirectory].path
                       stringByAppendingPathComponent:@"vector.pca.scale"];
    
    predictPath = [[self applicationDocumentsDirectory].path
                   stringByAppendingPathComponent:@"vector.pca.predict"];
    
    emotions = @[@"Angry", @"Contempt", @"Disgust", @"Fear", @"Happy", @"Sadness", @"Surprise", @"Natural/Other"];
    
    
    eigsize = 18;
    
    file2eig(wtPathString,eigv, eigsize);
    file2vect(muPathString, mu);
    file2vect(sigmaPathString, sigma);
    
    
    
    classify = false;


}

-(void) outputEmotion
{
    NSArray *lines, *indexes, *values;
    NSMutableArray *results = [NSMutableArray array];
    lines = [[NSString stringWithContentsOfFile:predictPath
                                      encoding:NSASCIIStringEncoding
                                         error:nil]
            componentsSeparatedByString:@"\n"];
    
    indexes = [lines[0] componentsSeparatedByString:@" "];
    values = [lines[1] componentsSeparatedByString:@" "];
    int label = [values[0] integerValue];
    
    
    // Initalise NSMutableArray with 8 objects
    for(int i = 0; i < 8; i++) {
        [results addObject:[NSNull null]];
    }
    // Place the predictions for each emotion in the right location of the array
    for (int i = 1; i<9; i++){
        int index = [indexes[i] integerValue];
        float value = [values[i] doubleValue];
        value = value * 100;
        NSString* formattedNumber = [NSString stringWithFormat:@"%2.4f", value];
        [results replaceObjectAtIndex:index-1 withObject:formattedNumber];
    }
    
    // Output these values to the screen
    for (int i = 0; i < 8; i++){
        NSString *emotionString = [NSString stringWithFormat:@"%@ = %@", emotions[i], [results objectAtIndex:i]];
        cv::putText(im, [emotionString UTF8String],
                    cv::Point(30, 50+(i*20)), cv::FONT_HERSHEY_COMPLEX_SMALL,
                    0.8, cv::Scalar::all(255));
    }
    
    

}
// Draw geometry of face on the screen
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

// Face tracking and classification (conditional on classify variable)
-(void)track
{
    const char *trainRangePathString = [trainRangePath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *trainPathString = [trainPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    const char *vectorPathString = [vectorPath cStringUsingEncoding:NSASCIIStringEncoding];

    const char *vectorScalePathString = [vectorScalePath cStringUsingEncoding:NSASCIIStringEncoding];
    
    if(failed) {
        wSize = wSize2;
    } else {
        wSize = wSize1;
    }
    
    // If successful tracking - draw the points and possibly classify
    if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0) {
        
        [self draw];
        failed = false;

        // Only executed if classification is enabled
        if (classify){
            // Convert the tracking data to the appropriate distance measures
            vect2test(model._shape, test);
            
            // Perform a PCA projection to produce features
            pca_project(test, eigv, mu, sigma, eigsize, feat);
            
            // Write principle features to a 'vector.pca' file
            featfiler(feat, vectorPath);
                        
            // Scale that data
            [svm scaleData:vectorPathString rangeFile:trainRangePathString];
            
            // SVM prediction based on scaled data
            [svm predictData:vectorScalePathString modelFile:trainPathString];
            
            // Output prediction values to the screen
            [self outputEmotion];

        }
    
    // If unsuccessful tracking - reset the model
    }else{
        
        [self resetModel];
        failed = true;
        
    }
    
    [self outputFPS];
}


// Keep track of system time to add an FPS value to the screen
-(void)outputFPS{
    uint64_t currTime = mach_absolute_time();
    double timeInSeconds = machTimeToSecs(currTime - prevTime);
    prevTime = currTime;
    double fps = 1.0 / timeInSeconds;
    fpsString =
    [NSString stringWithFormat:@"FPS = %3.2f",
     fps];
    cv::putText(im, [fpsString UTF8String],
                cv::Point(30, 30), cv::FONT_HERSHEY_COMPLEX,
                0.8, cv::Scalar::all(0));
}



// Reset the tracking model
-(void)resetModel
{
    model.FrameReset();
}

// Toggles classification
-(void)classify
{
    classify ^= true;
}

// Tracks with UIImage - not used
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

// Tracks with OpenCV matrix - not used
-(UIImage *)trackWithCvMat:(cv::Mat)frame
{
    
    if(scale == 1)im = frame;
    else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
    cv::flip(im,im,1);
    cv::cvtColor(im,gray,CV_BGR2GRAY);
    
    [self track];
    
    return [imageConverter UIImageFromMat:im];
    
}

// Gets the tracking model rotation
- (NSMutableArray *)getRotation
{
    cv::Mat pose = model._clm._pglobl;
    
    NSMutableArray *rotationArray = [[NSMutableArray alloc] initWithCapacity:3];

    
    for (int i = 0; i<3; i++) {
        
        [rotationArray addObject:[NSNumber numberWithDouble:pose.at<double>(i, 0)]];
    }


    return rotationArray;
    
}

// Get the tracking model scale - not used
-(double)getScale {
	CvMat pose = model._clm._pglobl;
	return cvGetReal2D(&pose,0,0) ;
}

// Get a 3D mesh based on the tracking model - not used
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
    
    return meshArray;
}

// Get a specific tracking point - not used
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

// Write a vector of features to a specific file
void featfiler (std::vector<double> &feat, NSString * filename)
{
    NSString *fStr = [[NSString alloc]init];
    for( std::vector<double>::size_type i=0; i<feat.size(); ++i ){
        fStr = [fStr stringByAppendingFormat:@"%lu:%f \n", i+1, feat[i]];
    }
    [fStr writeToFile:filename
           atomically:YES
                 encoding:NSASCIIStringEncoding error:NULL];
    
}

// Function to take the eigenvalues from PCA into an eigen value array
void file2eig(const char * filename,std::vector<double> eigv[], int eigsize)
{
    std::string currentLine;
    std::ifstream infile;
    infile.open (filename);
    int ctr=1, idx;
    while(ctr<eigsize+1) // To get top 'eigsize' number of eigen vectors
    {
        
        getline(infile,currentLine); // Saves the line in currentLine.
        char *cstr = new char[currentLine.length() + 1];
        strcpy(cstr, currentLine.c_str());
        char *p = strtok(cstr, ",");
        idx=1;
        while (p) {
            eigv[ctr-1].push_back(atof(p));
            p = strtok(NULL, ",");
            idx++;
        }
        ctr++;
        
    }
    
    infile.close();
    return;
}

// Perform PCA projection based on PCA data from training and distance measures acquired from tracking data
void pca_project (std::vector<double> &test, std::vector<double> eigv[],
                  std::vector<double> mu, std::vector<double> sigma, int eigsize, std::vector<double> &feat)
{
    int ctr = 0;
    double sum = 0;
    feat.clear();
    while(ctr<eigsize){
        sum = 0;
        for (std::vector<double>::size_type i = 0; i<test.size();++i){
            sum += (eigv[ctr][i]*(test[i]-mu[i])/sigma[i]);
        }
        feat.push_back(sum);
        ++ctr;
    }
    
}

float distance_between(Point2d n1, Point2d n2)
{
    return sqrt(((n1.x - n2.x)*(n1.x - n2.x)) + ((n1.y - n2.y)*(n1.y - n2.y)));
}

void setEqlim(cv::Mat &shape, int rows, int cols, cv::Rect &facereg)
{
    double top, left, right, bottom;
    int n = shape.rows / 2;
    if (shape.at<double>(0, 0) < 20.5) {
        if (shape.at<double>(0, 0) < 0)
            left = 0;
        else
            left = shape.at<double>(0, 0);
    } else
        left = shape.at<double>(0, 0) - 20;
    
    if (shape.at<double>(16, 0) + 20 > cols - 0.5) {
        if (shape.at<double>(16, 0) > cols)
            right = cols;
        else
            right = shape.at<double>(16, 0);
    } else
        right = shape.at<double>(16, 0) + 20;
    
    if (shape.at<double>(8 + n, 0) > rows - 0.5) {
        if (shape.at<double>(8 + n, 0) > rows)
            bottom = rows;
        else
            bottom = shape.at<double>(8 + n, 0);
    } else
        bottom = shape.at<double>(8 + n, 0) + 20;
    
    if (shape.at<double>(19 + n, 0) < 10.5) {
        if (shape.at<double>(19 + n, 0) < 0)
            top = 0;
        else
            top = shape.at<double>(19 + n, 0);
    } else
        top = shape.at<double>(19 + n, 0) - 10;
    
    facereg= cv::Rect(Point2d(left, top), Point2d(right, bottom));
    
    return;
    
}

void vect2test (cv::Mat &vect, std::vector<double> &test)
{
    int i, n = vect.rows/2;
    cv::Point2d left_eye, right_eye, nose;
    
    float between_eyes;
    test.clear();
    left_eye = cv::Point2d(vect.at<double>(36,0)/2+vect.at<double>(39,0)/2,vect.at<double>(36+n,0)/2+vect.at<double>(39+n,0)/2);
    right_eye = cv::Point2d(vect.at<double>(42,0)/2+vect.at<double>(45,0)/2,vect.at<double>(42+n,0)/2+vect.at<double>(45+n,0)/2);
    between_eyes = distance_between(left_eye, right_eye);
    cv::Point2d p1, p2;
    nose = cv::Point2d((vect.at<double>(30,0)+vect.at<double>(33,0))/2,(vect.at<double>(30+n,0)+vect.at<double>(33+n,0))/2);
    
    for(i = 0 ; i < 17;  i++)
    {
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    for(i = 17; i < 22;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,left_eye)/between_eyes);
    }
    for(i = 22; i < 27;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,right_eye)/between_eyes);
    }
    for(i = 31; i < 36;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    for(i = 36; i < 42;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,left_eye)/between_eyes);
    }
    for(i = 42; i < 48;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,right_eye)/between_eyes);
    }
    for(i = 48; i < 66;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    for(i = 0; i < 5;  i++)
    {
        
        p1 = Point2d(vect.at<double>(17+i,0), vect.at<double>(17+i+n,0));
        p2 = Point2d(vect.at<double>(26-i,0), vect.at<double>(26-i+n,0));
        test.push_back(distance_between(p1,p2)/between_eyes);
    }
    
    
    for(i = 22; i < 27;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    for(i = 17; i < 22;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    for(i = 0; i < 3;  i++)
    {
        
        p1 = Point2d(vect.at<double>(56+i,0), vect.at<double>(56+i+n,0));
        p2 = Point2d(vect.at<double>(52-i,0), vect.at<double>(52-i+n,0));
        test.push_back(distance_between(p1,p2)/between_eyes);
    }
    
	   p1 = Point2d(vect.at<double>(48,0), vect.at<double>(48+n,0));
	   p2 = Point2d(vect.at<double>(54,0), vect.at<double>(54+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);
    
	   p1 = Point2d(vect.at<double>(49,0), vect.at<double>(49+n,0));
	   p2 = Point2d(vect.at<double>(53,0), vect.at<double>(53+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);
    
	   p1 = Point2d(vect.at<double>(59,0), vect.at<double>(59+n,0));
	   p2 = Point2d(vect.at<double>(55,0), vect.at<double>(55+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);
    
    for(i = 0; i < 3;  i++)
    {
        
        p1 = Point2d(vect.at<double>(60+i,0), vect.at<double>(60+i+n,0));
        p2 = Point2d(vect.at<double>(65-i,0), vect.at<double>(65-i+n,0));
        test.push_back (distance_between(p1,p2)/between_eyes);
    }
    
    //printf("Test (1) = %f\n", test.front());
    return;
    
    
    
}

void file2vect (const char* filename, std::vector<double> &vect)
{
    std::string currentLine;
    std::ifstream infile;
    infile.open (filename);
    int idx = 0;
    vect.clear();
    if(!infile.eof())
    {
        getline(infile,currentLine); // Saves the line in currentLine.
        char *cstr = new char[currentLine.length() + 1];
        strcpy(cstr, currentLine.c_str());
        char *p = strtok(cstr, ","); //separate using comma delimiter
        idx=1;
        while (p) {
            vect.push_back(atof(p));
            p = strtok(NULL, ",");
            idx++;
        }
    }
    
    infile.close();
    
    
}

// Tracks with CVImageBufferRef - currently used
-(UIImage *)trackWithCVImageBufferRef:(CVImageBufferRef)imageBuffer
{

    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    //size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
    
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

// Convert measured time to seconds for screen display (FPS)
static double machTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e9;
}

// Returns the location of the applications document directory where we can write to
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}



@end
