//
//  trackerWrapper.h
//
//  Created by Tom Hartley on 01/12/2012.
//  Modified and documented by Matthew Jones on 09/09/2015
//  Copyright (c) 2012 Tom Hartley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import "Tracker.h"
#import "imageConversion.h"
#import "svmWrapper.h"
#import <AVFoundation/AVFoundation.h>

@interface trackerWrapper : NSObject


/*!
 @brief Initialises tracking model, image conversion, and SVM wrapper
 
 @discussion This method will load in the .tracker files required by the FaceTracker library, as well as initialise the image converter and SVM wrapper.
 
 @remark This method should once needs to be run once after view load

 */
-(void)initialiseModel;


/*!
 @brief Initialises various values for the face tracker and the emotion classification
 
 @discussion This method will set values such as tracking parameters, file paths, emotions to be used, and values required by PCA projection.
 
 @remark This method only needs to be run once after view load
 */
-(void)initialiseValues;


/*!
 @brief Resets face tracking model
 
 @discussion This method will reset the frame for the FaceTracker library. Triggered whenever there is unsuccessful tracking. Can also be manually triggered.
 */
-(void)resetModel;

/*!
 @brief Toggles emotion classification
 
 @discussion This method will flip a boolean variable that controls whether the SVM will run on the tracked data. By default, classification is disabled.
 */
-(void)classify;

/*!
 @brief Processes a frame from the image buffer
 
 @discussion This method will convert a frame from the image buffer to an OpenCV matrix, will run the tracking code on this matrix, and then will produce an output UIImage that can be displayed
 
 @param imageBuffer Core Video image buffer that manages the frames captured from the camera
 
 @return UIImage A single processed frame from the buffer, ready for display
 */
-(UIImage *)trackWithCVImageBufferRef:(CVImageBufferRef)imageBuffer;


@end