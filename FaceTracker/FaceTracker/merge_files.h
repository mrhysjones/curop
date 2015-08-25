/*
 * merge_files.h
 *
 *  Created on: 15-Jul-2015
 *  Author: abhijat
 *  Modified by: Matthew Rhys Jones
 *
 */

#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>
#include "svm.h"

#ifndef MERGE_FILES_H_
#define MERGE_FILES_H_
 
void output_target(double value);
void output(int index, double value);
char* readline(FILE *input);
int clean_up(FILE *fp_restore, FILE *fp, const char *msg);
void predict(svm_model* svmmodel,struct svm_node *x);
int svmrun (svm_model* svmmodel, const char *vectorfile, const char *emotionfile);



#endif /* MERGE_FILES_H_ */
