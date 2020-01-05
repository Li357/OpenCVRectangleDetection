//
//  RectangleDetection.m
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 12/29/19.
//  Copyright © 2019 Andrew Li. All rights reserved.
//

#ifdef __cplusplus

#import <numeric>
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#endif

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "RectangleDetector.h"
#import "Rectangle.h"

// "private" methods with C++ prototypes
@interface RectangleDetector()

+ (CGPoint) convertToCGPoint:(cv::Point)point;
+ (void) autoCannyOn:(cv::InputArray)src into:(cv::OutputArray)edges withSigma:(double)sigma;
+ (double) cosOfAngleBetweenPoints:(cv::Point)p1 and:(cv::Point)p2 withPivot:(cv::Point)p0;

@end

@implementation RectangleDetector

- (instancetype)initWithEpsilon:(double)epsilon maximumSize:(int)maximumSize quadratureTolerance:(double)quadratureTolerance {
    self = [super init];
    if (self) {
        DP_EPSILON_FACTOR = epsilon;
        MINIMUM_SIZE = maximumSize;
        QUADRATURE_TOLERANCE = quadratureTolerance;
    }
    return self;
}

+ (CGPoint) convertToCGPoint:(cv::Point)point
{
    return CGPointMake((CGFloat)point.x, (CGFloat)point.y);
}

+ (void) autoCannyOn:(cv::InputArray)src into:(cv::OutputArray)edges withSigma:(double)sigma
{
    std::vector<double> vec;
    src.getMat().reshape(0, 1).copyTo(vec);

    std::nth_element(vec.begin(), vec.end() + vec.size() / 2, vec.end());
    double median = vec[vec.size() / 2];

    int lower = floor(std::max<double>(0, (1 - sigma) * median));
    int upper = floor(std::min<double>(255, (1 + sigma) * median));
    cv::Canny(src, edges, lower, upper);
}

+ (double) cosOfAngleBetweenPoints:(cv::Point)p1 and:(cv::Point)p2 withPivot:(cv::Point)p0
{
    double dx1 = p1.x - p0.x;
    double dy1 = p1.y - p0.y;
    double dx2 = p2.x - p0.x;
    double dy2 = p2.y - p0.y;
    return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}

- (NSMutableArray *) findRectanglesIn:(UIImage *)image
{
    cv::Mat original;
    UIImageToMat(image, original);

    cv::Mat mat;
    original.copyTo(mat);

    cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    cv::GaussianBlur(mat, mat, cv::Size(5, 5), 0);
    [[self class] autoCannyOn:mat into:mat withSigma:0.33];

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(mat, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    std::sort(contours.begin(), contours.end(), [](auto c1, auto c2) -> bool {
        return cv::contourArea(c1) > cv::contourArea(c2);
    });

    NSMutableArray *rectangles = [[NSMutableArray alloc] init];
    size_t numContours = std::min<size_t>(contours.size(), 20);
    for (int i = 0; i < numContours; i++) {
        auto contour = contours[i];
        double perimeter = cv::arcLength(cv::Mat(contour), true);

        std::vector<cv::Point> approx;
        cv::approxPolyDP(cv::Mat(contour), approx, DP_EPSILON_FACTOR * perimeter, true);

        if (approx.size() == 4 && fabs(cv::contourArea(approx)) > MINIMUM_SIZE && cv::isContourConvex(approx)) {
            double maxCosine = 0;
            for (int j = 2; j < 5; j++) {
                double absCosine = fabs([[self class] cosOfAngleBetweenPoints:approx[j % 4] and:approx[j - 2] withPivot:approx[j - 1]]);
                maxCosine = std::max(maxCosine, absCosine);
            }

            if (maxCosine <= QUADRATURE_TOLERANCE) {
                CGPoint topLeft = [[self class] convertToCGPoint:approx[0]];
                CGPoint topRight = [[self class] convertToCGPoint:approx[1]];
                CGPoint bottomRight = [[self class] convertToCGPoint:approx[2]];
                CGPoint bottomLeft = [[self class] convertToCGPoint:approx[3]];

                Rectangle *rect = [[Rectangle alloc] initWithTopLeft:topLeft topRight:topRight bottomRight:bottomRight bottomLeft:bottomLeft];
                [rectangles addObject:rect];
            }
        }
    }
    return rectangles;
}

@end
