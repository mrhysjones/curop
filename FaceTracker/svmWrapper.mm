//
//  svmWrapper.mm
//  FaceTracker
//
//  Created by Matthew Jones on 28/08/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "svmWrapper.h"
#import <string>

using namespace std;

@implementation svmWrapper {
    
}

#define max(x,y) (((x)>(y))?(x):(y))
#define min(x,y) (((x)<(y))?(x):(y))

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
long int num_nonzeros = 0;
long int new_num_nonzeros = 0;

NSArray *paths = NSSearchPathForDirectoriesInDomains
(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = [paths objectAtIndex:0];


// Variables specific to svm-predict
int predict_probability = 0;
struct svm_node *x;
struct svm_model* model;
int max_nr_attr = 64;
static int (*info)(const char *fmt,...) = &printf;
int max_line_len = 1024;
char* ln = NULL;

-(int)scaleData:(const char*) vectorFile rangeFile: (const char*) rangeFile{
    
    int i, index;
    FILE *vect, *range = NULL;
    NSString *scaleLocation = [NSString stringWithFormat:@"%@/vector.pca.scale",
                               documentsDirectory];
    NSString *scaledVals = @"1 ";
    
    // File containing the test data after PCA projection
    vect = fopen(vectorFile, "r");
    
    // Scaling factors file from the SVM model
    range = fopen(rangeFile, "r");
    
    // File to output the scaled values
    
    // Check files can be opened - this will be called many times so need to check
    if (vect == NULL || range == NULL){
        fprintf(stderr,"Unable to open vector or range file \n");
        exit(1);
    }
    
    // Allocate memory to store stream from files
    l = (char *) malloc(max_line_length*sizeof(char));
    
#define SKIP_TARGET\
    while(isspace(*p)) ++p;\
    while(!isspace(*p)) ++p;
    
#define SKIP_ELEMENT\
    while(*p!=':') ++p;\
        ++p;\
    while(isspace(*p)) ++p;\
    while(*p && !isspace(*p)) ++p;
    
    /*
     * Assumed min index is normally 1 - should always be in our case.
     * max_index may differ depending on model - have hardcoded but can
     * add extra step to check indexes based on pass 1 in svm-scale
     *
     */
    max_index = 18;
    min_index = 1;
    
    feature_max = (double *)malloc((max_index + 1) * sizeof(double));
    feature_min = (double *)malloc((max_index + 1) * sizeof(double));
    
    y_max = 18;
    y_min = 1;
    
    /* Find out the min/max value of test features */
    while(readScaleLine(vect) != NULL){
        char *p=l;
        int next_index=1;
        double value;
        
        SKIP_TARGET
        
        while(sscanf(p,"%d:%lf",&index,&value)==2)
        {
            for(i=next_index;i<index;i++)
            {
                feature_max[i]=max(feature_max[i],0);
                feature_min[i]=min(feature_min[i],0);
            }
            
            feature_max[index]=max(feature_max[index],value);
            feature_min[index]=min(feature_min[index],value);
            
            SKIP_ELEMENT
            next_index=index+1;
        }
        
        for(i=next_index;i<=max_index;i++)
        {
            feature_max[i]=max(feature_max[i],0);
            feature_min[i]=min(feature_min[i],0);
        }
    }
    
    rewind(vect);
    
    /* Save/restore feature_min/feature_max */
    
    /* fp_restore rewinded in finding max_index */
    int idx, c;
    double fmin, fmax;
    int next_index = 1;
    
    if((c = fgetc(range)) == 'y')
    {
        if(fscanf(range, "%lf %lf\n", &y_lower, &y_upper) != 2 ||
           fscanf(range, "%lf %lf\n", &y_min, &y_max) != 2)
            return clean_up(range, vect, "ERROR: failed to read scaling parameters\n");
        y_scaling = 1;
    }
    else
        ungetc(c, range);
    
    if (fgetc(range) == 'x')
    {
        if(fscanf(range, "%lf %lf\n", &lower, &upper) != 2)
            return clean_up(range, vect, "ERROR: failed to read scaling parameters\n");
        while(fscanf(range,"%d %lf %lf\n",&idx,&fmin,&fmax)==3)
        {
            for(i = next_index;i<idx;i++)
                if(feature_min[i] != feature_max[i])
                    fprintf(stderr,
                            "WARNING: feature index %d appeared in file %s was not seen in the scaling factor file %s.\n",
                            i, vectorFile , rangeFile);
            
            feature_min[idx] = fmin;
            feature_max[idx] = fmax;
            next_index = idx + 1;
        }
        
        for(i=next_index;i<=max_index;i++)
            if(feature_min[i] != feature_max[i])
                fprintf(stderr,
                        "WARNING: feature index %d appeared in file %s was not seen in the scaling factor file %s.\n",
                        i, vectorFile, rangeFile);
    }
    
    /* Perform scaling */
    while(readScaleLine(vect) != NULL){
        char *p = l;
        double value;
        double newValue;
        
        while(sscanf(p,"%d:%lf",&index,&value)==2)
        {
            newValue = output(index,value);
            NSString *toAppend = [NSString stringWithFormat:@"%d:%g ",index, newValue];
            scaledVals = [scaledVals stringByAppendingString:toAppend];
            
            SKIP_ELEMENT
        }
    }
    
    /* Write scaled values to file */
    
    [scaledVals writeToFile:scaleLocation
                 atomically:YES
                   encoding:NSASCIIStringEncoding error:NULL];
    
    fclose(range);
    fclose(vect);
    free(feature_max);
    free(feature_min);
    free(l);
    
    return 0;
}


-(int)predictData:(const char *)scaleFile modelFile:(const char *)modelFile{
    FILE* scaledVals = NULL;
    predict_probability = 1;
    
    // Open 'vector.pca.scale'
    scaledVals = fopen(scaleFile, "r");
    if(scaledVals == NULL)
    {
        fprintf(stderr,"can't open input file %s\n",scaleFile);
        exit(1);
    }
    // Load in the SVM model
    if((model=svm_load_model(modelFile))==0)
    {
        fprintf(stderr,"can't open model file %s\n",modelFile);
        exit(1);
    }
    // Allocate X (for predictions)
    x = (struct svm_node *) malloc(max_nr_attr*sizeof(struct svm_node));
    
    [self predict:scaledVals];
    svm_free_and_destroy_model(&model);
    free(x);
    free(ln);
    fclose(scaledVals);
    
    
    
    return 0;
}

-(void)predict:(FILE *) input
{
    NSString *predictLocation = [NSString stringWithFormat:@"%@/vector.pca.predict",
                                 documentsDirectory];
    NSString *predictString = @"";
    int correct = 0;
    int total = 0;
    double error = 0;
    double sump = 0, sumt = 0, sumpp = 0, sumtt = 0, sumpt = 0;
    
    int svm_type=svm_get_svm_type(model);
    int nr_class=svm_get_nr_class(model);
    double *prob_estimates=NULL;
    int j;
    
    
    
    if(predict_probability)
    {
        if (svm_type==NU_SVR || svm_type==EPSILON_SVR)
            info("Prob. model for test data: target value = predicted value + z,\nz: Laplace distribution e^(-|z|/sigma)/(2sigma),sigma=%g\n",svm_get_svr_probability(model));
        else
        {
            int *labels=(int *) malloc(nr_class*sizeof(int));
            svm_get_labels(model,labels);
            prob_estimates = (double *) malloc(nr_class*sizeof(double));
            predictString = @"labels";
            for(j=0;j<nr_class;j++){
                NSString *toAppend = [NSString stringWithFormat:@" %d",labels[j]];
                predictString = [predictString stringByAppendingString:toAppend];
            }
            NSString *newLine = @"\n";
            predictString = predictString = [predictString stringByAppendingString:newLine];
            free(labels);
        }
    }
    
    max_line_len = 1024;
    ln = (char *)malloc(max_line_len*sizeof(char));
    while(readPredictLine(input) != NULL)
    {
        int i = 0;
        double target_label, predict_label;
        char *idx, *val, *label, *endptr;
        int inst_max_index = -1; // strtol gives 0 if wrong format, and precomputed kernel has <index> start from 0
        
        label = strtok(ln," \t\n");
        if(label == NULL) // empty line
            exit_input_error(total+1);
        
        target_label = strtod(label,&endptr);
        if(endptr == label || *endptr != '\0')
            exit_input_error(total+1);
        
        while(1)
        {
            if(i>=max_nr_attr-1)	// need one more for index = -1
            {
                max_nr_attr *= 2;
                x = (struct svm_node *) realloc(x,max_nr_attr*sizeof(struct svm_node));
            }
            
            idx = strtok(NULL,":");
            val = strtok(NULL," \t");
            
            if(val == NULL)
                break;
            errno = 0;
            x[i].index = (int) strtol(idx,&endptr,10);
            if(endptr == idx || errno != 0 || *endptr != '\0' || x[i].index <= inst_max_index)
                exit_input_error(total+1);
            else
                inst_max_index = x[i].index;
            
            errno = 0;
            x[i].value = strtod(val,&endptr);
            if(endptr == val || errno != 0 || (*endptr != '\0' && !isspace(*endptr)))
                exit_input_error(total+1);
            
            ++i;
        }
        x[i].index = -1;
        
        if (predict_probability && (svm_type==C_SVC || svm_type==NU_SVC))
        {
            predict_label = svm_predict_probability(model,x,prob_estimates);
            
            NSString* label = [NSString stringWithFormat:@"%g", predict_label];
            predictString = [predictString stringByAppendingString:label];
            
            for(j=0;j<nr_class;j++){
                NSString* estimate = [NSString stringWithFormat:@" %g", prob_estimates[j]];
                predictString = [predictString stringByAppendingString:estimate];
            }
            
            NSString *newLine = @"\n";
            predictString = predictString = [predictString stringByAppendingString:newLine];
        }
        else
        {
            predict_label = svm_predict(model,x);
            NSString* label = [NSString stringWithFormat:@"%g\n",predict_label];
            predictString = [predictString stringByAppendingString:label];
        }
        
        if(predict_label == target_label)
            ++correct;
        error += (predict_label-target_label)*(predict_label-target_label);
        sump += predict_label;
        sumt += target_label;
        sumpp += predict_label*predict_label;
        sumtt += target_label*target_label;
        sumpt += predict_label*target_label;
        ++total;
    }
    
    if(predict_probability)
        free(prob_estimates);
    
    /* Write prediction values to file */
    [predictString writeToFile:predictLocation
                    atomically:YES
                      encoding:NSASCIIStringEncoding error:NULL];
    
}



void output_target(double value)
{
    if(y_scaling)
    {
        if(value == y_min)
            value = y_lower;
        else if(value == y_max)
            value = y_upper;
        else value = y_lower + (y_upper-y_lower) *
            (value - y_min)/(y_max-y_min);
    }
    printf("%g ",value);
}

double output(int index, double value)
{
    /* skip single-valued attribute */
    if(feature_max[index] == feature_min[index])
        return 0;
    
    if(value == feature_min[index])
        value = lower;
    else if(value == feature_max[index])
        value = upper;
    else
        value = lower + (upper-lower) *
        (value-feature_min[index])/
        (feature_max[index]-feature_min[index]);
    
    return value;
    
}

char* readScaleLine(FILE *input){
    int len;
    
    if(fgets(l,max_line_length,input) == NULL)
        return NULL;
    
    while(strrchr(l,'\n') == NULL)
    {
        max_line_length *= 2;
        l = (char *) realloc(l, max_line_length);
        len = (int) strlen(l);
        if(fgets(l+len,max_line_length-len,input) == NULL)
            break;
    }
    return l;
}

char* readPredictLine(FILE *input){
    int len;
    
    if(fgets(ln,max_line_len,input) == NULL)
        return NULL;
    
    while(strrchr(ln,'\n') == NULL)
    {
        max_line_len *= 2;
        ln = (char *) realloc(ln, max_line_len);
        len = (int) strlen(ln);
        if(fgets(ln+len,max_line_len-len,input) == NULL)
            break;
    }
    return ln;
}



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

void exit_input_error(int line_num)
{
    fprintf(stderr,"Wrong input format at line %d\n", line_num);
    exit(1);
}

@end;

