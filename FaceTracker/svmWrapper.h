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
-(NSMutableArray*)scaleData:(const char*) rangeFile test: (std::vector<double>) test;
-(NSMutableArray*)predictData:(NSMutableArray*) scaledVals;


@end
