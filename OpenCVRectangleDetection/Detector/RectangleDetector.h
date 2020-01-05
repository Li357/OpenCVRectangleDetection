//
//  RectangleDetector.h
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 12/29/19.
//  Copyright © 2019 Andrew Li. All rights reserved.
//

#ifndef RectangleDetector_h
#define RectangleDetector_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RectangleDetector : NSObject
{
    double DP_EPSILON_FACTOR;
    int MINIMUM_SIZE;
    double QUADRATURE_TOLERANCE;
}

- (instancetype)initWithEpsilon:(double)epsilon maximumSize:(int)maximumSize quadratureTolerance:(double)quadratureTolerance;
- (NSMutableArray *) findRectanglesIn:(UIImage *)image;

@end

#endif /* RectangleDetector_h */
