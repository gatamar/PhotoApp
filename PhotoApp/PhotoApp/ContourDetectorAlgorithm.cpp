//
//  ContourDetectorAlgorithm.cpp
//  PhotoApp
//
//  Created by Olha Pavliuk on 6/17/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

#include "ContourDetectorAlgorithm.h"
#include <opencv2/imgproc.hpp>

std::vector<std::vector<cv::Point>> getContours(cv::Mat& edges, const ContourParams& params);
cv::Mat getImageForContourDetection(cv::Mat& src);
cv::Mat getBinaryImageWithContours(int rows, int cols, const std::vector<std::vector<cv::Point>>& contours, const ContourParams& params);
cv::Mat getHoughLinesP(cv::Mat& edges);
void smoothLineWithGaussianKernel(std::vector<CGPoint>& vec, int kern_size, float sigma);
int clampi(int x, int a, int b);
CGPoint CGPointScaled(const CGPoint& p, float scale);

std::vector<std::vector<CGPoint>> findContours(const MyImage& img, const ContourParams& params, float& algo_scale)
{
    cv::Mat src = cv::Mat( img.getHeight(), img.getWidth(), CV_8UC4, img.getData() );
    assert( !src.empty() );
    
    cv::Mat src_small;
    algo_scale = std::max(src.rows, src.cols)/300;
    cv::resize(src, src_small, cv::Size(src.cols/algo_scale, src.rows/algo_scale));
    
    cv::Mat gray = getImageForContourDetection(src_small);
    cv::Mat canny_edges;
    cv::Canny(gray, canny_edges, params.m_canny_t1, params.m_canny_t2);
    std::vector<std::vector<cv::Point>> contours = getContours(canny_edges, params);
    
    int small_rows = canny_edges.rows, small_cols = canny_edges.cols;
    
    cv::Mat binary = getBinaryImageWithContours(src_small.rows, src_small.cols, contours, params);
    cv::Mat linesP = getHoughLinesP(binary);
    
    cv::Mat contours_big;
    cv::resize(binary, contours_big, cv::Size(img.getWidth(), img.getHeight()));
    cv::cvtColor(contours_big, contours_big, cv::COLOR_GRAY2BGRA);
    
    std::vector<std::vector<CGPoint>> contours2(contours.size());
    for ( int i=0;i<contours.size();++i)
    {
        std::vector<CGPoint>& contours2_cur = contours2[i];
        contours2_cur.reserve(contours[i].size());
        for (int j =0; j<contours[i].size(); ++j)
            contours2_cur.push_back( CGPointMake(contours[i][j].x, contours[i][j].y) );
        smoothLineWithGaussianKernel(contours2_cur, 3, params.m_sigma);
    }
    
    return contours2;
}

cv::Mat getImageForContourDetection(cv::Mat& src)
{
    cv::Mat src_small = src;
    cv::blur(src_small, src_small, cv::Size(3,3));
    cv::Mat hsv_small;
    cv::cvtColor(src_small, hsv_small, cv::COLOR_BGR2HSV);
    
    std::vector<cv::Mat> channels_hsv;
    cv::split(hsv_small, channels_hsv);
    
    return channels_hsv[2];
}

cv::Mat getBinaryImageWithContours(int rows, int cols, const std::vector<std::vector<cv::Point>>& contours, const ContourParams& params)
{
    cv::Mat contours_binary = cv::Mat::zeros(rows, cols, CV_8UC1);
    for (int i=0; i<contours.size(); i++)
    {
        if ( contours[i].size() < params.m_min_contour_size ) continue;
        
        for ( int p=1; p<contours[i].size(); ++p)
        {
            cv::line(contours_binary, contours[i][p-1], contours[i][p], cv::Scalar(255));
        }
    }
    
    cv::blur(contours_binary, contours_binary, cv::Size(3,3));
    return contours_binary;
}

cv::Mat getHoughLinesP(cv::Mat& edges)
{
    double rho = 1;
    double theta = CV_PI/180;
    int threshold = 10;
    double minLineLength = 0;
    double maxLineGap = 0;
    assert( edges.type() == CV_8UC1 );
    
    cv::Mat linesP;
    cv::HoughLinesP(edges, linesP, rho, theta, threshold, minLineLength, maxLineGap);
    return linesP;
}

std::vector<std::vector<cv::Point>> getContours(cv::Mat& edges, const ContourParams& params)
{
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edges, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    return contours;
}

void smoothLineWithGaussianKernel(std::vector<CGPoint>& vec, int kern_size, float sigma)
{
    if (vec.size()<=1) return;
    std::vector<CGPoint> smooth(vec.size());
    std::vector<float> gaussian_blur_koefs(2*kern_size+1);
    
    float sum = 0;
    for ( int i=0; i<gaussian_blur_koefs.size(); ++i)
    {
        gaussian_blur_koefs[i] = (float)exp(-(i-kern_size)*(i-kern_size)/sigma/sigma);
        sum += gaussian_blur_koefs[i];
    }
    // TODO: add accumulator here
    for ( int i=0; i<gaussian_blur_koefs.size(); ++i)
        gaussian_blur_koefs[i] /= sum;
    
    // write smoothed {vec} into {smooth}
    const int n = int(vec.size());
    for(int i=0; i<n; ++i)
    {
        CGPoint res = CGPointZero;
        for(int j=-kern_size;j<=kern_size;++j)
        {
            CGPoint p = CGPointScaled(vec[clampi(i+j, 0, n-1)], gaussian_blur_koefs[j+kern_size]);
            res.x += p.x;
            res.y += p.y;
        }
        smooth[i] = res;
    }
    
    // restore "edge" elements
    smooth.insert(smooth.begin(), vec[0]);
    smooth.push_back(vec.back());
    
    vec = std::move(smooth);
}

int clampi(int x, int a, int b)
{
    if ( x < a ) return a;
    if ( x > b ) return b;
    
    return x;
}

CGPoint CGPointScaled(const CGPoint& p, float scale)
{
    return CGPointMake(p.x*scale, p.y*scale);
}
