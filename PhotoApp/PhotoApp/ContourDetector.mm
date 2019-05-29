//
//  ContourDetector.cpp
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/29/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

#import "ContourDetector.h"
#import <CoreGraphics/CoreGraphics.h>
#include <opencv2/imgproc.hpp>

void smoothLineWithGaussianKernel(std::vector<CGPoint>& vec, int kern_size, float sigma);

struct ContourParams
{
    int m_canny_t1 = 0;
    int m_canny_t2 = 255;
    int m_min_contour_size = 10;
    float m_sigma = 2;
};

struct MyLine
{
    CGPoint p1;
    CGPoint p2;
};

class MyImage
{
    int m_width = 0, m_height = 0;
    unsigned char* m_rgba = 0;

public:
    MyImage()
    {
        
    }
    ~MyImage()
    {
        delete [] m_rgba;
    }
    int getWidth() const { return m_width; }
    int getHeight() const { return m_height; }
};

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

cv::Mat getBinaryImageWithContours(int rows, int cols, const std::vector<std::vector<cv::Point>>& contours, ContourParams& params)
{
    cv::Mat contours_binary = cv::Mat::zeros(rows, cols, CV_8UC1);
    for (int i=0; i<contours.size(); i++)
    {
        if ( contours[i].size() < params.m_min_contour_size ) continue;
        
        //unsigned colors [] = { 0xFFFF00, 0x00FF00, 0xFF00FF, 0xFF0000, 0x0000FF };
        for ( int p=1; p<contours[i].size(); ++p)
        {
            //const cv::Point& pt = contours[i][p];
            cv::line(contours_binary, contours[i][p-1], contours[i][p], cv::Scalar(255));
        }
    }
    
    //cv::dilate(contours_binary, contours_binary, cv::Mat());
    
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

std::vector<std::vector<cv::Point>> getContours(cv::Mat& edges, ContourParams& params)
{
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edges, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    return contours;
}

void processImageForLines(const MyImage& in, ContourParams& params)
{
    unsigned char* bytes_to_allock = 0;
    cv::Mat src; // TODO: convert "in" to src.
    assert( src.empty() );
    
    cv::Mat src_small;
    float work_scale = std::max(src.rows, src.cols)/300;
    cv::resize(src, src_small, cv::Size(src.cols/work_scale, src.rows/work_scale));
    
    cv::Mat gray = getImageForContourDetection(src_small);
    cv::Mat canny_edges;
    cv::Canny(gray, canny_edges, params.m_canny_t1, params.m_canny_t2);
    std::vector<std::vector<cv::Point>> contours = getContours(canny_edges, params);
    
    int small_rows = canny_edges.rows, small_cols = canny_edges.cols;
    
    cv::Mat binary = getBinaryImageWithContours(src_small.rows, src_small.cols, contours, params);
    cv::Mat linesP = getHoughLinesP(binary);
    
    delete [] bytes_to_allock;
    
    cv::Mat contours_big;
    cv::resize(binary, contours_big, cv::Size(in.getWidth(), in.getHeight()));
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
    
    std::vector<MyLine> result_lines;
    for ( int i=0; i<contours2.size(); ++i)
    {
        for ( int k=1; k<contours2[i].size(); ++k)
        {
            MyLine cur_line;
            cur_line.p1 = contours2[i][k-1]; //* work_scale
            cur_line.p2 = contours2[i][k]; //* work_scale
            result_lines.push_back(cur_line);
        }
    }
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

// TODO: do it with CGPoint
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
