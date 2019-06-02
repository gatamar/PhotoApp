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

@interface ContourDetector : NSObject

- (NSArray<Line*>*)detectLines:(CVPixelBufferRef)pixelBuffer;

@end

