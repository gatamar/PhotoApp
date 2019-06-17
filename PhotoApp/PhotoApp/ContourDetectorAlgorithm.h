//
//  ContourDetectorAlgorithm.hpp
//  PhotoApp
//
//  Created by Olha Pavliuk on 6/17/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

#ifndef ContourDetectorAlgorithm_hpp
#define ContourDetectorAlgorithm_hpp

#include <vector>
#include <CoreGraphics/CGGeometry.h>

class MyImage
{
    int m_width = 0, m_height = 0;
    unsigned char* m_rgba = 0;
    
public:
    MyImage() = default;
    MyImage(int w, int h, unsigned char* rgba, bool owner=true): m_width(w), m_height(h)
    {
        if ( owner )
            m_rgba = rgba;
        else
        {
            m_rgba = new unsigned char[w*h*4];
            memcpy(m_rgba, rgba, w*h*4);
        }
    }
    ~MyImage()
    {
        if (m_rgba) delete [] m_rgba;
    }
    int getWidth() const { return m_width; }
    int getHeight() const { return m_height; }
    unsigned char* getData() const { return m_rgba; }
};

struct ContourParams
{
    int m_canny_t1 = 0;
    int m_canny_t2 = 255;
    int m_min_contour_size = 10;
    float m_sigma = 2;
};

std::vector<std::vector<CGPoint>> findContours(const MyImage& img, const ContourParams& params, float& algo_scale);

#endif /* ContourDetectorAlgorithm_hpp */
