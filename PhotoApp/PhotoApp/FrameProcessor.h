//
//  ContourDetector.hpp
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/29/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface Line: NSObject

@property (assign) CGPoint p1;
@property (assign) CGPoint p2;

@end

@protocol FrameProcessorDelegate

- (void)onLinesDetected:(NSArray<Line*>*)lines;

@end

@interface FrameProcessor : NSObject

@property (nonatomic, assign) CGSize aspectFillSize;

- (id)initWithDelegate:(id<FrameProcessorDelegate>)delegate;

- (NSArray<Line*>*)detectLines:(CVPixelBufferRef)pixelBuffer;

// Synchronous operation. Modifies "bgra_bytes"
- (void)applySimpleFilter:(unsigned char*)bgra_bytes
                withWidth:(int)width
                andHeight:(int)height
                andStride:(int)stride;

// Synchronous operation. Returns detected lines.
- (NSArray<Line*>*)detectLines1:(CVPixelBufferRef)pixelBuffer;

// Asynchronous operation. Processes lines in background thread.
// Receives retained "pixelBuffer". Releases "pixelBuffer" after work is done.
- (void)detectLines2:(CVPixelBufferRef)pixelBuffer;

// Asynchronous operation. Processes lines in background thread.
// Copies "pixelBuffer" to avoid retaining it.
- (void)detectLines3:(CVPixelBufferRef)pixelBuffer;

@end

