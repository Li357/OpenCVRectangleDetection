//
//  Rectangle.m
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 1/5/20.
//  Copyright © 2020 Andrew Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Rectangle.h"

@implementation Rectangle

- (instancetype)initWithTopLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomRight:(CGPoint)bottomRight bottomLeft:(CGPoint)bottomLeft
{
    self = [super init];
    if (self) {
        _topLeft = topLeft;
        _topRight = topRight;
        _bottomRight = bottomRight;
        _bottomLeft = bottomLeft;
    }
    return self;
}

@end
