//
//  trackerWrapper.m
//
//  Created by Tom Hartley on 01/12/2012.
//  Modified and documented by Matthew Jones on 09/09/2015
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
    NSString *trainRangePath, *muPath, *sigmaPath, *wtPath, *fpsString;
    NSArray *emotions;
    NSMutableArray *scaledValues, *predictedValues;
    
}

-(void)initialiseModel
{
    // Paths for supporting files required by face tracker library
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"face2" ofType:@"tracker"];
    NSString *triPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"tri"];
    NSString *conPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"con"];
    
    const char *modelPathString = [modelPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *triPathString = [triPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *conPathString = [conPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    // Load face tracker model, triangulation data, and connection data
    model.Load(modelPathString);
    tri=FACETRACKER::IO::LoadTri(triPathString);
    con=FACETRACKER::IO::LoadCon(conPathString);
    
    
    // Path for the SVM model used to classify
    NSString *trainPath = [[NSBundle mainBundle] pathForResource:@"emotions.train.pca" ofType:@"model"];
    const char* trainPathString = [trainPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    // Initialise svmWrapper and load in the model
    svm = [[svmWrapper alloc] init];
    [svm loadModel:trainPathString];
    
    // Initialise the image converter
    imageConverter = [[imageConversion alloc] init];
    
}

-(void)initialiseValues
{
    // Keeps track of previous time to use for FPS calculation
    prevTime = mach_absolute_time();
    
    // Face tracker parameters
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
    
    
    // File paths required for PCA and scaling
    trainRangePath = [[NSBundle mainBundle] pathForResource:@"emotions.train.pca" ofType:@"range"];
    wtPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_wt" ofType:@"txt"];
    muPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_mu" ofType:@"txt"];
    sigmaPath = [[NSBundle mainBundle] pathForResource:@"pca_archive_sigma" ofType:@"txt"];
    const char *wtPathString = [wtPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *muPathString = [muPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *sigmaPathString = [sigmaPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    // Emotions that are being predicted (for screen output)
    emotions = @[@"Angry", @"Contempt", @"Disgust", @"Fear", @"Happy", @"Sadness", @"Surprise", @"Natural/Other"];
    
    // Number of principle component variances
    eigsize = 18;
    
    // Load in files needed for PCA
    file2eig(wtPathString,eigv, eigsize);
    file2vect(muPathString, mu);
    file2vect(sigmaPathString, sigma);
    
    // By default, classification is off
    classify = false;
}

/*!
 @brief Output predicted values for each emotion on frame
 
 @discussion This method is used to draw each emotion and prediction onto the screen
 */
-(void) outputEmotion
{
    // Output these values to the screen
    for (int i = 0; i < 8; i++){
        double prediction = [[predictedValues objectAtIndex:i] doubleValue] * 100;
        NSString *predPercent = [NSString stringWithFormat:@"%2.4f", prediction];
        NSString *emotionString = [NSString stringWithFormat:@"%@ = %@", emotions[i], predPercent];
        cv::putText(im, [emotionString UTF8String],
                    cv::Point(30, 50+(i*20)), cv::FONT_HERSHEY_COMPLEX_SMALL,
                    0.8, cv::Scalar::all(255));
    }
}

/*!
 @brief Draws the geometry of tracked face 
 
 @discussion This method is used to draw the triangulation, connections, and the individual points obtained from the face tracker model
 */
-(void) draw
{
    // Obtain data from the face tracker model
    cv::Mat shape = model._shape;
    cv::Mat visi = model._clm._visi[model._clm.GetViewIdx()];
    
    
    int i,n = shape.rows/2; cv::Point p1,p2; cv::Scalar c;

    c = CV_RGB(255,0,0);
    
    // Draw triangulation
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

    // Draw connections
    for(i = 0; i < con.cols; i++){
        if(visi.at<int>(con.at<int>(0,i),0) == 0 ||
           visi.at<int>(con.at<int>(1,i),0) == 0)continue;
        p1 = cv::Point(shape.at<double>(con.at<int>(0,i),0),
                       shape.at<double>(con.at<int>(0,i)+n,0));
        p2 = cv::Point(shape.at<double>(con.at<int>(1,i),0),
                       shape.at<double>(con.at<int>(1,i)+n,0));
        cv::line(im,p1,p2,c,1);
    }
    
    // Draw points
    for(i = 0; i < n; i++){
        if(visi.at<int>(i,0) == 0)continue;
        p1 = cv::Point(shape.at<double>(i,0),shape.at<double>(i+n,0));
        c = CV_RGB(0,255,0); cv::circle(im,p1,2,c);
        
    }
}
/*!
 @brief Runs face tracker and conditionally runs the emotion classification
 
 @discussion This method is used to draw the triangulation, connections, and the individual points obtained from the face tracker model
 */
-(void)track
{
    const char *trainRangePathString = [trainRangePath cStringUsingEncoding:NSASCIIStringEncoding];


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
            
            scaledValues = [svm scaleData:trainRangePathString test:feat];
            predictedValues = [svm predictData:scaledValues];
            
            // Output FPS and prediction values to the screen
            [self outputEmotion];

        }
        [self outputFPS];
    
    // If unsuccessful tracking - reset the model
    }else{
        [self outputFPS];
        [self resetModel];
        failed = true;
        
    }
}

/*!
 @brief Outputs current frames per second value to screen
 
 @discussion Uses the mach_time to keep track of current/previous times, and uses these values to produce an estimate for FPS
*/

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

-(void)resetModel
{
    model.FrameReset();
    [self outputFPS];
}

-(void)classify
{
    classify ^= true;
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

/*!
 @brief Reduce dimensions of features through PCA
 
 @discussion This method reduce the dimensions of the vector of distance measures acquired from the face tracker model through principle component analysis
 
 @param test    A single vector of distance measures from the face tracker
 @param eigv    A vector of principal component variances
 @param mu  A vector of the estimated means
 @param sigma   A vector of the sums
 @param eigsize Number of principal component variances from training
 @param feat    A vector containing a reduced number of features
 
 */
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

/*!
 @brief Distance between two points
 
 @discussion Computes distance between two points - used to obtain distance measures
 
 @param n1  First point
 @param n2  Second point
*/
float distance_between(Point2d n1, Point2d n2)
{
    return sqrt(((n1.x - n2.x)*(n1.x - n2.x)) + ((n1.y - n2.y)*(n1.y - n2.y)));
}

/*!
 @brief Produces distance measures from tracking points
 
 @discussion This method will produce 86 new distance measures from the points obtained by the face tracker.
 
 @param vect    Vector of points obtained from face tracker
 @param test    Vector of computed distance measures
 */
void vect2test (cv::Mat &vect, std::vector<double> &test)
{
    int i, n = vect.rows/2;
    cv::Point2d left_eye, right_eye, nose;
    
    float between_eyes;
    test.clear();
    
    // Normalise all points by the distance between eyes
    left_eye = cv::Point2d(vect.at<double>(36,0)/2+vect.at<double>(39,0)/2,vect.at<double>(36+n,0)/2+vect.at<double>(39+n,0)/2);
    right_eye = cv::Point2d(vect.at<double>(42,0)/2+vect.at<double>(45,0)/2,vect.at<double>(42+n,0)/2+vect.at<double>(45+n,0)/2);
    between_eyes = distance_between(left_eye, right_eye);
    
    // As well as each eye, nose is used as a fixed point to measure from
    nose = cv::Point2d((vect.at<double>(30,0)+vect.at<double>(33,0))/2,(vect.at<double>(30+n,0)+vect.at<double>(33+n,0))/2);
    cv::Point2d p1, p2;
    
    
    // Jaw points to nose centre distances
    for(i = 0 ; i < 17;  i++)
    {
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    
    // Left eyebrow points to left eye centre distances
    for(i = 17; i < 22;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,left_eye)/between_eyes);
    }
    
    
    // Right eyebrow points to left eye centre distances
    for(i = 22; i < 27;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,right_eye)/between_eyes);
    }
    
    // Nose bridge to nose centre distances
    for(i = 31; i < 36;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    
    // Left eye points to left eye centre distances
    for(i = 36; i < 42;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,left_eye)/between_eyes);
    }
    
    // Right eye points to right eye centre distances
    for(i = 42; i < 48;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,right_eye)/between_eyes);
    }
    
    // Mouth points to nose centre distances
    for(i = 48; i < 66;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    
    // Left eyebrow points to right eyebrow points distances
    for(i = 0; i < 5;  i++)
    {
        
        p1 = Point2d(vect.at<double>(17+i,0), vect.at<double>(17+i+n,0));
        p2 = Point2d(vect.at<double>(26-i,0), vect.at<double>(26-i+n,0));
        test.push_back(distance_between(p1,p2)/between_eyes);
    }
    
    // Left eyebrow points to nose centre distances
    for(i = 17; i < 22;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    
    // Right eyebrow points to nose centre distances
    for(i = 22; i < 27;  i++)
    {
        
        p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
        test.push_back(distance_between(p1,nose)/between_eyes);
    }
    
    // Top of mouth to bottom of mouth distances
    for(i = 0; i < 3;  i++)
    {
        
        p1 = Point2d(vect.at<double>(56+i,0), vect.at<double>(56+i+n,0));
        p2 = Point2d(vect.at<double>(52-i,0), vect.at<double>(52-i+n,0));
        test.push_back(distance_between(p1,p2)/between_eyes);
    }
    
    // Corners of mouth distances
    p1 = Point2d(vect.at<double>(48,0), vect.at<double>(48+n,0));
    p2 = Point2d(vect.at<double>(54,0), vect.at<double>(54+n,0));
    test.push_back(distance_between(p1,p2)/between_eyes);
    
    p1 = Point2d(vect.at<double>(49,0), vect.at<double>(49+n,0));
    p2 = Point2d(vect.at<double>(53,0), vect.at<double>(53+n,0));
    test.push_back(distance_between(p1,p2)/between_eyes);
    
    p1 = Point2d(vect.at<double>(59,0), vect.at<double>(59+n,0));
    p2 = Point2d(vect.at<double>(55,0), vect.at<double>(55+n,0));
    test.push_back(distance_between(p1,p2)/between_eyes);
    
    // Centre of mouth distances
    for(i = 0; i < 3;  i++)
    {
        
        p1 = Point2d(vect.at<double>(60+i,0), vect.at<double>(60+i+n,0));
        p2 = Point2d(vect.at<double>(65-i,0), vect.at<double>(65-i+n,0));
        test.push_back (distance_between(p1,p2)/between_eyes);
    }
    return;
}

/*!
 @brief Reads a file into a vector
 
 @discussion This method is used to read in values from a file into a vector. Currently used for obtaining mu and sigma
 
 @param filename    Filepath to read
 @param vect    A vector containing read in values
 */
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
/*!
 @brief Reads eigenvalues from file 
 
 @discussion This method is used to read in eigenvalues from a file into a vector. It also obtains the number of eigenvalues
 
 @param filename    Filepath to read
 @param eigv    A vector containing read in values
 @param eigsize Number of eigen vectors
 */
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

/*!
 @brief Converts mach_time into seconds
 
 @discussion This method puts the mach_time into the human readable form of seconds using the mach_timebase
 
 @param time A mach_time value
 @return Seconds representation of input
 */
static double machTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e9;
}

@end
