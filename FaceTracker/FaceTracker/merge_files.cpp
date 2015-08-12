#include "svm.h"
#include "merge_files.h"
#include <array>
#include <iostream>
#include <vector>

using namespace std;

struct svm_node *x = (struct svm_node *) malloc(20*sizeof(struct svm_node));

int x_i = 0;

double lower=-1.0,upper=1.0,y_lower,y_upper;
int y_scaling = 0;
double *feature_max;
double *feature_min;
double y_max = -DBL_MAX;
double y_min = DBL_MAX;

long int num_nonzeros = 0;
long int new_num_nonzeros = 0;

#define max(x,y) (((x)>(y))?(x):(y))
#define min(x,y) (((x)<(y))?(x):(y))


int svmrun(svm_model* svmmodel, const char * vectorfile, const char* emotionfile)
{
	int max_line_len = 1024;
	double target_label, predict_label;
	x = (struct svm_node *) malloc(20*sizeof(struct svm_node));
	x_i=0;
	int max_index;
	int min_index;
	int i,index;
    
    
	FILE *fp			= fopen(vectorfile,"r");
	FILE *fp_restore 	= fopen(emotionfile,"r");



	//Declare prev. globals
	char *line = NULL;

	line = (char *) malloc(max_line_len*sizeof(char));

#define SKIP_TARGET\
	while(isspace(*p)) ++p;\
	while(!isspace(*p)) ++p;

#define SKIP_ELEMENT\
	while(*p!=':') ++p;\
	++p;\
	while(isspace(*p)) ++p;\
	while(*p && !isspace(*p)) ++p;

	/* assumption: min index of attributes is 1 */
	/* pass 1: find out max index of attributes */
	max_index = 0;
	min_index = 1;


	int idx, c;

	c = fgetc(fp_restore);
	if(c == 'y')
	{
		readline(fp_restore, line);
		readline(fp_restore, line);
		readline(fp_restore, line);
	}
	readline(fp_restore, line);
	readline(fp_restore, line);

	while(fscanf(fp_restore,"%d %*f %*f\n",&idx) == 1)
		max_index = max(idx,max_index);
	rewind(fp_restore);


	while(readline(fp, line)!=NULL)
	{
		char *p=line;

		SKIP_TARGET

		while(sscanf(p,"%d:%*f",&index)==1)
		{
			max_index = max(max_index, index);
			min_index = min(min_index, index);
			SKIP_ELEMENT
			num_nonzeros++;
		}
	}

	rewind(fp);

	feature_max = (double *)malloc((max_index+1)* sizeof(double));
	feature_min = (double *)malloc((max_index+1)* sizeof(double));

	for(i=0;i<max_index;i++)
	{
		feature_max[i]=-DBL_MAX;
		feature_min[i]=DBL_MAX;
	}

	/* pass 2: find out min/max value */
	while(readline(fp, line)!=NULL)
	{
		char *p=line;
		int next_index=1;
		double target;
		double value;

		if (sscanf(p,"%lf",&target) != 1)
			return clean_up(fp_restore, fp, "ERROR: failed to read labels\n", line);
		y_max = max(y_max,target);
		y_min = min(y_min,target);
		target_label = target;
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

	rewind(fp);


	/* fp_restore rewinded in finding max_index */
	double fmin, fmax;
	int next_index = 1;

	if((c = fgetc(fp_restore)) == 'y')
	{
		if(fscanf(fp_restore, "%lf %lf\n", &y_lower, &y_upper) != 2 ||
		   fscanf(fp_restore, "%lf %lf\n", &y_min, &y_max) != 2)
			return clean_up(fp_restore, fp, "ERROR: failed to read scaling parameters\n", line);
		y_scaling = 1;
	}
	else
		ungetc(c, fp_restore);

	if (fgetc(fp_restore) == 'x')
	{
		if(fscanf(fp_restore, "%lf %lf\n", &lower, &upper) != 2)
			return clean_up(fp_restore, fp, "ERROR: failed to read scaling parameters\n", line);
		while(fscanf(fp_restore,"%d %lf %lf\n",&idx,&fmin,&fmax)==3)
		{
			feature_min[idx] = fmin;
			feature_max[idx] = fmax;

			next_index = idx + 1;
		}

	}
	fclose(fp_restore);

	/* pass 3: scale */
	while(readline(fp, line)!=NULL)
	{
		char *p=line;
		next_index = 1;
		double target;
		double value;

		if (sscanf(p,"%lf",&target) != 1)
			return clean_up(NULL, fp, "ERROR: failed to read labels\n", line);
		output_target(target);

		SKIP_TARGET

		while(sscanf(p,"%d:%lf",&index,&value)==2)
		{
			for(i=next_index;i<index;i++)
				output(i,0);

			output(index,value);

			SKIP_ELEMENT
			next_index=index+1;
		}

		for(i=next_index;i<=max_index;i++)
			output(i,0);

		printf("\n");
	}
	rewind(fp);
	free(line);
	free(feature_max);
	free(feature_min);
	fclose(fp);
	predict(svmmodel, x, predict_label);

	free(x);
	return 0;
}

char* readline(FILE *input, char *line = NULL)
{
	int len;
	int max_line_len = 1024;
	if(fgets(line,max_line_len,input) == NULL)
		return NULL;

	while(strrchr(line,'\n') == NULL)
	{
		max_line_len *= 2;
		len = (int) strlen(line);
		if(fgets(line+len,max_line_len-len,input) == NULL)
			break;
	}
	return line;
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
//	printf("%g ",value);
}

void output(int index, double value)
{

	/* skip single-valued attribute */
	if(feature_max[index] == feature_min[index])
		return;

	if(value == feature_min[index])
		value = lower;
	else if(value == feature_max[index])
		value = upper;
	else
		value = lower + (upper-lower) *
			(value-feature_min[index])/
			(feature_max[index]-feature_min[index]);


	if(value != 0)
	{
//		printf("\n%d:%g ", index, value);
		x[x_i].index = index;
		x[x_i].value = value;
//		printf("\n%d:%g ", x_i, value);
		++x_i;

		new_num_nonzeros++;
	}
}

int clean_up(FILE *fp_restore, FILE *fp, const char* msg, char *line = NULL)
{
	free(line);
	free(feature_max);
	free(feature_min);
	fclose(fp);
	if (fp_restore)
		fclose(fp_restore);
	return -1;
}

void predict(svm_model* svmmodel, struct svm_node *x, double predict_label)
{
	double *prob_estimates = NULL;
	std::array<std::string,8> emotions = {"Angry", "Contempt", "Disgust", "Fear", "Happy", "Sadness","Surprise","Natural/Other"};

	int nr_class = svm_get_nr_class(svmmodel);
	prob_estimates = (double *) realloc(prob_estimates,nr_class*sizeof(double));
	predict_label = svm_predict_probability(svmmodel,x,prob_estimates);
	printf("%g\n",predict_label);

	for (unsigned int a = 0; a < 8; a++){
		cout << emotions[a] << ":" << 100*prob_estimates[a] << "%" << endl;
	}

	free(prob_estimates);
	return;
}
