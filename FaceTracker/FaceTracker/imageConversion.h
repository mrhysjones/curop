//
//  imageConversion.h
//  iOSFaceTracker2
//
//  Created by Tom Hartley on 02/12/2012.
//  Copyright (c) 2012 Tom Hartley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface imageConversion : NSObject


-(cv::Mat)cvMatWithImage:(UIImage *)image;
-(UIImage *)UIImageFromMat:(cv::Mat)image;

@end


