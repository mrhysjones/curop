//
//  svmWrapper.mm
//  FaceTracker
//
//  Created by Matthew Jones on 28/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import <float.h>
#import <stdio.h>
#import <stdlib.h>
#import <ctype.h>
#import <string>
#import <errno.h>
#import <vector>
#import "svm.h"


@interface svmWrapper : NSObject


/*!
 @brief Loads SVM model from model file
 
 @discussion This method will call the libSVM method svm_load_model, to create an svm_model to be used throughout the application
 
 @remark This method is called once when the view loads
 */
-(void)loadModel:(const char *)modelFile;


/*!
 @brief Performs SVM scaling on data
 
 @discussion This method is based on libSVM svm-scale and is used to scale the test data with respect to the scaling factors file associated with the model
 
 @param rangeFile   Scaling factors file 
 @param test    Vector of test data
 
 @return NSMutableArray Scaled test data
 
 */
-(NSMutableArray*)scaleData:(const char*) rangeFile test: (std::vector<double>) test;

/*!
 @brief Performs SVM predictions on data
 
 @discussion This method is based on libSVM svm-predict and is used to predict the probability estimates from a multi-class SVM model
 
 @param scaledVals  Array of scaled test values
 
 @return NSMutableArray Probability estimates for each class of emotion
 
 */
-(NSMutableArray*)predictData:(NSMutableArray*) scaledVals;


@end
