//
//  svmWrapper.mm
//  FaceTracker
//
//  Created by Matthew Jones on 28/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "svmWrapper.h"

using namespace std;

@implementation svmWrapper {
    
}

// Macro functions to compute min/max
#define max(x,y) (((x)>(y))?(x):(y))
#define min(x,y) (((x)<(y))?(x):(y))

// Variables specific to scaleData
char *l =  NULL;
int max_line_length = 1024;
double lower = -1.0, upper = 1.0;
double y_lower, y_upper;
int y_scaling = 0;
double *feature_max;
double *feature_min;
double y_max = -DBL_MAX;
double y_min = DBL_MAX;
int max_index;
int min_index;

// Variables specific to predictData
int predict_probability = 0;
struct svm_node *x;
struct svm_model* model;
int max_nr_attr = 64;


-(NSMutableArray*)scaleData:(const char*) rangeFile test:(std::vector<double>) test{
    
    int i, index;
    max_index = 18;
    min_index = 1;
    
    feature_max = (double *)malloc((max_index + 1) * sizeof(double));
    feature_min = (double *)malloc((max_index + 1) * sizeof(double));
    
    y_max = 18;
    y_min = 1;
    
    // Load in scaling file
    FILE* range = NULL;
    range = fopen(rangeFile, "r");
    if (range == NULL){
        printf("Unable to read scaling factors file");
        exit(1);
    }
    
    int next_index=1;
    double value;
    
    // Work out feature min/max from test data
    for (int j = 0; j < test.size(); j++){
        index = j+1;
        value = test.at(j);
        for(i=next_index;i<index;i++)
        {
            feature_max[i]=max(feature_max[i],0);
            feature_min[i]=min(feature_min[i],0);
        }
        
        feature_max[index]=max(feature_max[index],value);
        feature_min[index]=min(feature_min[index],value);
        
        next_index=index+1;
    
    
        for(i=next_index;i<=max_index;i++)
        {
            feature_max[i]=max(feature_max[i],0);
            feature_min[i]=min(feature_min[i],0);
        }
    }
    int idx, c;
    double fmin, fmax;
    next_index = 1;
    
    // Work out feature min/max from scaling factors file 
    if((c = fgetc(range)) == 'y')
    {
        if(fscanf(range, "%lf %lf\n", &y_lower, &y_upper) != 2 ||
           fscanf(range, "%lf %lf\n", &y_min, &y_max) != 2)
            clean_up(range, NULL, "ERROR: failed to read scaling parameters\n");
        y_scaling = 1;
    }
    else
        ungetc(c, range);
    
    if (fgetc(range) == 'x')
    {
        if(fscanf(range, "%lf %lf\n", &lower, &upper) != 2)
            clean_up(range, NULL, "ERROR: failed to read scaling parameters\n");
        while(fscanf(range,"%d %lf %lf\n",&idx,&fmin,&fmax)==3)
        {
            for(i = next_index;i<idx;i++)
                if(feature_min[i] != feature_max[i])
                    fprintf(stderr,
                            "WARNING: feature index %d appeared in vector was not seen in the scaling factor file %s.\n",
                            i, rangeFile);
            
            feature_min[idx] = fmin;
            feature_max[idx] = fmax;
            next_index = idx + 1;
        }
        
        for(i=next_index;i<=max_index;i++)
            if(feature_min[i] != feature_max[i])
                fprintf(stderr,
                        "WARNING: feature index %d appeared in vector was not seen in the scaling factor file %s.\n",
                        i, rangeFile);
    }
    
    // Perform scaling and add to scaledVals array
    NSMutableArray *scaledVals = [[NSMutableArray alloc] init];
    
    for (int j = 0; j <= test.size(); j++){
        [scaledVals addObject:[NSNull null]];
    }
    
    for (int j = 0; j < test.size(); j++){
        NSNumber *index = [NSNumber numberWithInt:j+1];
        NSNumber *value = [NSNumber numberWithDouble:test.at(j)];
        NSNumber *newValue = [self output:index value:value];
        [scaledVals insertObject:newValue atIndex:j+1];
        
    }
    
    fclose(range);
    free(feature_max);
    free(feature_min);
    return scaledVals;
}


-(NSMutableArray*)predictData:(NSMutableArray*) scaledVals{
    NSMutableArray *predictions = [[NSMutableArray alloc] init];
    
    x = (struct svm_node *) malloc(max_nr_attr*sizeof(struct svm_node));
    
    // Number of classes in SVM model
    int nr_class=svm_get_nr_class(model);
    
    
    double *prob_estimates=NULL;
    
    // Get the label ordering from the SVM model
    int *labels=(int *) malloc(nr_class*sizeof(int));
    svm_get_labels(model,labels);
    prob_estimates = (double *) malloc(nr_class*sizeof(double));
    
    int i = 0;
    double predict_label;
    
    // Build SVM node based on scaled values
    for (int j = 1; j < 18; j++){
        x[i].index = j;
        x[i].value = [[scaledVals objectAtIndex:j] doubleValue];
        ++i;
    }
    
    // Add a -1 node to signal the end of the data
    x[i].index = -1;
    
    // Obtain estimates for each class, as well as the predicted label
    predict_label = svm_predict_probability(model,x,prob_estimates);
    
    // Put the predicted values into a predicted values array with respect to label ordering
    for(int i = 0; i < 8; i++) {
        [predictions addObject:[NSNull null]];
    }
    for(int j=0; j<nr_class;j++){
        NSNumber* val = [NSNumber numberWithDouble:prob_estimates[j]];
        [predictions replaceObjectAtIndex:labels[j]-1 withObject:val];
    }
    free(x);
    free(labels);
    free(prob_estimates);
    
    return predictions;
}


/*!
 @brief Scales a single feature
 
 @discussion Using the feature_max and feature_min arrays, for a given value at a particular feature index, this method will return a new scaled value to be used by the prediction function
 
 @param index   Feature index
 @param value   Original value of feature
 
 @return NSNumber   Scaled value of feature
 */

-(NSNumber*)output:(NSNumber*) index value:(NSNumber*) value{
    int idx = [index intValue];
    double val = [value doubleValue];
    if(feature_max[idx] == feature_min[idx])
        return 0;
    
    if(val == feature_min[idx])
        val = lower;
    else if(val == feature_max[idx])
        val = upper;
    else
        val = lower + (upper-lower) *
        (val-feature_min[idx])/
        (feature_max[idx]-feature_min[idx]);
    
    NSNumber* newVal = [NSNumber numberWithDouble:val];
    return newVal;
    
}


-(void)loadModel:(const char *)modelFile{
    if((model=svm_load_model(modelFile))==0)
    {
        fprintf(stderr,"Can't open the SVM model %s\n",modelFile);
        exit(1);
    }
}


/*!
 @brief Cleans up during scaling
 
 @discussion If scaling process fails, this function is called to deallocate memory and to close any open files
 
 @param fp_restore  A vector file to scale (currently passed as NULL)
 @param fp  Vector scaling factors file
 @param msg Message to output to give reasoning for failure
 
 @return int    -1 when complete
 */

int clean_up(FILE *fp_restore, FILE *fp, const char* msg)
{
    fprintf(stderr,	"%s", msg);
    free(l);
    free(feature_max);
    free(feature_min);
    fclose(fp);
    if (fp_restore)
        fclose(fp_restore);
    return -1;
}


@end;


