//
//  Rectangle.h
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 1/5/20.
//  Copyright © 2020 Andrew Li. All rights reserved.
//

#ifndef Rectangle_h
#define Rectangle_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface Rectangle : NSObject

@property (nonatomic, readonly) CGPoint topLeft;
@property (nonatomic, readonly) CGPoint topRight;
@property (nonatomic, readonly) CGPoint bottomRight;
@property (nonatomic, readonly) CGPoint bottomLeft;

- (instancetype)initWithTopLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomRight:(CGPoint)bottomRight bottomLeft:(CGPoint)bottomLeft;

@end

#endif /* Rectangle_h */
