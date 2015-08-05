/*
 * vecthelp.h
 *
 *  Created on: 08-Jul-2015
 *      Author: abhijat
 */

#ifndef VECTHELP_H_
#define VECTHELP_H_

#include <math.h>
#include <vector>
#include <sstream>
#include <fstream>
#include <iostream>
#include <string>

typedef cv::Point_<double> Point2d;

void vect2test (cv::Mat &shape, std::vector<double> &test);
void file2vect (char* filename, std::vector<double> &vect);
void pca_project (std::vector<double> &test, std::vector<double> eigv[], int eigsize, std::vector<double> &feat);
void file2eig(const char * filename,std::vector<double> eigv[], int eigsize);
void featfiler (std::vector<double> &feat, const char* filename);


void featfiler (std::vector<double> &feat, const char* filename="vector.pca")
{
	FILE* file = fopen(filename, "w+");
	fprintf(file, "1 ");
	for( std::vector<double>::size_type i=0; i<feat.size(); ++i ){
		fprintf( file, "%lu:%f ", i+1, feat[i]);
//		printf("%lu:%f ", i+1, feat[i]);
	}
	fclose(file);
}

void file2eig(const char * filename,std::vector<double> eigv[], int eigsize)
{
    std::string currentLine;
    std::ifstream infile;
    infile.open (filename);
    int ctr=1, idx;
    while(ctr<eigsize+1) // To get top 'eigsize' number of eigen vectors
    {

        getline(infile,currentLine); // Saves the line in currentLine.
        char *cstr = new char[currentLine.length() + 1];
		strcpy(cstr, currentLine.c_str());
		char *p = strtok(cstr, ",");
		idx=1;
		while (p) {
			eigv[ctr-1].push_back(atof(p));
			//printf ("Token %d (%d): %f, size now(%lu)\n", ctr, idx, eigv[ctr-1].back(),eigv[ctr-1].size());
			p = strtok(NULL, ",");
			idx++;
		}
		ctr++;

    }

    infile.close();
    return;
}

void pca_project (std::vector<double> &test, std::vector<double> eigv[],
std::vector<double> mu, std::vector<double> sigma, int eigsize, std::vector<double> &feat)
{
	int ctr = 0;
	double sum = 0;
	feat.clear();
	while(ctr<eigsize){
		sum = 0;
		for (std::vector<double>::size_type i = 0; i<test.size();++i){
			sum += (eigv[ctr][i]*(test[i]-mu[i])/sigma[i]);
//			printf(" test(%lu): %f\n", i,test[i]);
		}
		feat.push_back(sum);
		//printf("Frontin' %d:  %f\n", ctr, feat.back());
		++ctr;
	}

//	for (std::vector<double>::size_type i = 0; i<feat.size();++i){
//				printf("Feat (%lu): %f\n", i,feat[i]);
//	}

}

float distance_between(Point2d n1, Point2d n2)
{
	return sqrt(((n1.x - n2.x)*(n1.x - n2.x)) + ((n1.y - n2.y)*(n1.y - n2.y)));
}

void setEqlim(cv::Mat &shape, int rows, int cols, cv::Rect &facereg)
{
	double top, left, right, bottom;
	int n = shape.rows / 2;
	if (shape.at<double>(0, 0) < 20.5) {
		if (shape.at<double>(0, 0) < 0)
			left = 0;
		else
			left = shape.at<double>(0, 0);
	} else
		left = shape.at<double>(0, 0) - 20;

	if (shape.at<double>(16, 0) + 20 > cols - 0.5) {
		if (shape.at<double>(16, 0) > cols)
			right = cols;
		else
			right = shape.at<double>(16, 0);
	} else
		right = shape.at<double>(16, 0) + 20;

	if (shape.at<double>(8 + n, 0) > rows - 0.5) {
		if (shape.at<double>(8 + n, 0) > rows)
			bottom = rows;
		else
			bottom = shape.at<double>(8 + n, 0);
	} else
		bottom = shape.at<double>(8 + n, 0) + 20;

	if (shape.at<double>(19 + n, 0) < 10.5) {
		if (shape.at<double>(19 + n, 0) < 0)
			top = 0;
		else
			top = shape.at<double>(19 + n, 0);
	} else
		top = shape.at<double>(19 + n, 0) - 10;

	facereg= cv::Rect(Point2d(left, top), Point2d(right, bottom));

	return;

}

void vect2test (cv::Mat &vect, std::vector<double> &test)
{
	int i, n = vect.rows/2;
	Point2d left_eye, right_eye, nose;
//	for (std::vector<double>::size_type i; i<n;i++){
//		printf("Vect [%lu]: (%f,%f)\n", i, vect.at<double>(i,0), vect.at<double>(i+n,0));
//	}

	float between_eyes;
	test.clear();
	left_eye = Point2d(vect.at<double>(36,0)/2+vect.at<double>(39,0)/2,vect.at<double>(36+n,0)/2+vect.at<double>(39+n,0)/2);
	right_eye = Point2d(vect.at<double>(42,0)/2+vect.at<double>(45,0)/2,vect.at<double>(42+n,0)/2+vect.at<double>(45+n,0)/2);
	between_eyes = distance_between(left_eye, right_eye);
	Point2d p1, p2;
//	printf("D = %f", between_eyes);
//	p1 = Point2d((vect.at<double>(19,0)+vect.at<double>(24,0))/2,vect.at<double>(19+n,0));
//	p2 = Point2d(vect.at<double>(8,0), vect.at<double>(9+n,0));
//	face_size = distance_between(p1,p2);
	nose = Point2d((vect.at<double>(30,0)+vect.at<double>(33,0))/2,(vect.at<double>(30+n,0)+vect.at<double>(33+n,0))/2);

//	printf("Point : (%f, %f)\n", vect.at<double>(30,0), vect.at<double>(30+n,0));
//	printf("D = %f\n", between_eyes);
//	printf("\nNose points: X %f, Y %f\n", vect.at<double>(30,0),vect.at<double>(30+n,0));


	for(i = 0 ; i < 17;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,nose)/between_eyes);
	 }
	for(i = 17; i < 22;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,left_eye)/between_eyes);
	 }
	for(i = 22; i < 27;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,right_eye)/between_eyes);
	 }
	for(i = 31; i < 36;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,nose)/between_eyes);
	 }
	for(i = 36; i < 42;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,left_eye)/between_eyes);
	 }
	for(i = 42; i < 48;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,right_eye)/between_eyes);
	 }
	for(i = 48; i < 66;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,nose)/between_eyes);
	 }
	for(i = 0; i < 5;  i++)
	 {

	   p1 = Point2d(vect.at<double>(17+i,0), vect.at<double>(17+i+n,0));
	   p2 = Point2d(vect.at<double>(26-i,0), vect.at<double>(26-i+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);
	 }


	for(i = 22; i < 27;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,nose)/between_eyes);
	 }
	for(i = 17; i < 22;  i++)
	 {

	   p1 = Point2d(vect.at<double>(i,0), vect.at<double>(i+n,0));
	   test.push_back(distance_between(p1,nose)/between_eyes);
	 }
	for(i = 0; i < 3;  i++)
	 {

	   p1 = Point2d(vect.at<double>(56+i,0), vect.at<double>(56+i+n,0));
	   p2 = Point2d(vect.at<double>(52-i,0), vect.at<double>(52-i+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);
	 }

	   p1 = Point2d(vect.at<double>(48,0), vect.at<double>(48+n,0));
	   p2 = Point2d(vect.at<double>(54,0), vect.at<double>(54+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);

	   p1 = Point2d(vect.at<double>(49,0), vect.at<double>(49+n,0));
	   p2 = Point2d(vect.at<double>(53,0), vect.at<double>(53+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);

	   p1 = Point2d(vect.at<double>(59,0), vect.at<double>(59+n,0));
	   p2 = Point2d(vect.at<double>(55,0), vect.at<double>(55+n,0));
	   test.push_back(distance_between(p1,p2)/between_eyes);

		for(i = 0; i < 3;  i++)
		 {

		   p1 = Point2d(vect.at<double>(60+i,0), vect.at<double>(60+i+n,0));
		   p2 = Point2d(vect.at<double>(65-i,0), vect.at<double>(65-i+n,0));
		   test.push_back (distance_between(p1,p2)/between_eyes);
		 }

		//printf("Test (1) = %f\n", test.front());
		return;



}

void file2vect (const char* filename, std::vector<double> &vect)
{
	std::string currentLine;
	std::ifstream infile;
	infile.open (filename);
	int idx = 0;
	vect.clear();
	if(!infile.eof())
	{
		getline(infile,currentLine); // Saves the line in currentLine.
		char *cstr = new char[currentLine.length() + 1];
		strcpy(cstr, currentLine.c_str());
		char *p = strtok(cstr, ","); //separate using comma delimiter
		idx=1;
		while (p) {
			vect.push_back(atof(p));
			//printf ("Token (%d): %f, size now(%lu)\n", idx, vect.back(),vect.size());
			p = strtok(NULL, ",");
			idx++;
		}
	}

		    infile.close();


}



#endif /* VECTHELP_H_ */
