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
#import <string.h>
#import <errno.h>
#import "svm.h"

@interface svmWrapper : NSObject

-(int)scaleData:(const char*) vectorFile rangeFile: (const char*) rangeFile;
-(int)predictData:(const char*) scaleFile;
-(void)loadModel:(const char *)modelFile;

@end
