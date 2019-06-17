//
//  ContourDetector.cpp
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/29/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

#import "FrameProcessor.h"
#import "ContourDetectorAlgorithm.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation Line
@end

class ImageToLayerTransform
{
private:
    float m_downscale = 0;
    CGSize m_shift = CGSizeZero;
    
public:
    ImageToLayerTransform(){}
    ImageToLayerTransform(float imageW, float imageH, float layerW, float layerH);
    float getDownscale() const { return m_downscale; }
    CGSize getShift() const { return m_shift; }
};

ImageToLayerTransform::ImageToLayerTransform(float imageW, float imageH, float layerW, float layerH)
{
    m_downscale = std::max(layerW/imageW, layerH/imageH);
    
    float imageScaledW = imageW*m_downscale, imageScaledH = imageH*m_downscale;
    m_shift = CGSizeMake((imageScaledW-layerW)/2, (imageScaledH-layerH)/2);
}

NSArray<Line*>* detectLinesInternal(const MyImage& img, ContourParams& params, const ImageToLayerTransform& transform)
{
    float algo_scale = 1;
    std::vector<std::vector<CGPoint>> contours = findContours(img, params, algo_scale);
    
    float downscale = transform.getDownscale();
    CGSize shift = transform.getShift();
    shift.width /= downscale;
    shift.height /= downscale;
    
    auto transformPoint = [=](const CGPoint& p) -> CGPoint
    {
        float x = (p.x*algo_scale-shift.width)*downscale;
        float y = (p.y*algo_scale-shift.height)*downscale;
        return CGPointMake(x, y);
    };
    
    NSMutableArray<Line*>* resultLines = [[NSMutableArray alloc] init];
    
    for ( int i=0; i<contours.size(); ++i)
        for ( int k=1; k<contours[i].size(); ++k)
        {
            Line* line = [[Line alloc] init];
            
            line.p1 = transformPoint(contours[i][k-1]);
            line.p2 = transformPoint(contours[i][k]);
            
            [resultLines addObject:line];
        }
    
    return resultLines;
}

@interface FrameProcessor ()

@property (nonatomic, weak) id<FrameProcessorDelegate> delegate;

@end

@implementation FrameProcessor

- (id)initWithDelegate:(id<FrameProcessorDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.delegate = delegate;
    }
    return self;
}

- (NSArray<Line*>*)detectLines:(CVPixelBufferRef)pixelBuffer
{
    assert( !CGSizeEqualToSize(self.aspectFillSize, CGSizeZero) );
    MyImage my_image = [self createMyImageFromPixelBuffer:pixelBuffer];
    ContourParams params;
    int imageW = (int)CVPixelBufferGetWidth(pixelBuffer);
    int imageH = (int)CVPixelBufferGetHeight(pixelBuffer);
    ImageToLayerTransform transform(imageW, imageH, _aspectFillSize.width, _aspectFillSize.height);
    return detectLinesInternal(my_image, params, transform);
}

- (CVPixelBufferRef)createBufferDeepCopy:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferRef pbCopy = NULL;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, CVPixelBufferGetPixelFormatType(pixelBuffer), NULL, &pbCopy);
    assert( status == 0 );
    
    CVPixelBufferLockBaseAddress(pbCopy, 0);
    void *copyBaseAddress = CVPixelBufferGetBaseAddress(pbCopy);
    memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow);
    CVPixelBufferUnlockBaseAddress(pbCopy, 0);
    
    return pbCopy;
}

// is there a possiblity to create cv::Mat from not-strided data? e.g. "bytesPerRow != width*4" ?
- (MyImage)createMyImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    unsigned char* baseAddress = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    unsigned char *rgba_data = new unsigned char[width*height*4];
    if ( bytesPerRow == width*4 )
        memcpy(rgba_data, baseAddress, width*height*4);
    else
    {
        for ( int y=0; y<height; ++y)
        {
            memcpy(rgba_data + y*width*4, baseAddress + y*bytesPerRow, width*4);
        }
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return MyImage(width, height, rgba_data);
}

@end
