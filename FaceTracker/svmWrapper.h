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

-(void)loadModel:(const char *)modelFile;
-(NSMutableArray*)scaleData:(const char*) rangeFile test: (std::vector<double>) test;
-(NSMutableArray*)predictData:(NSMutableArray*) scaledVals;


@end
