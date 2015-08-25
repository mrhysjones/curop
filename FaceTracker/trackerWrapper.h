//
//  trackerWrapper.h
//  iOSFaceTracker 2
//
//  Created by Tom Hartley on 01/12/2012.
//  Copyright (c) 2012 Tom Hartley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import "Tracker.h"
#import "imageConversion.h"
#import <AVFoundation/AVFoundation.h>


@interface trackerWrapper : NSObject

-(void)initialiseModel;
-(void)initialiseValues;
-(void)resetModel;
-(void)classify;
-(UIImage *)trackWithImage:(UIImage *)im;
-(UIImage *)trackWithCvMat:(cv::Mat)im;
-(UIImage *)trackWithCVImageBufferRef:(CVImageBufferRef)imageBuffer;
-(NSMutableArray *)getRotation;
-(double)getScale;
-(NSArray *) get3dMesh;
-(NSArray *)getSpecificPoint:(int)point;





@end
