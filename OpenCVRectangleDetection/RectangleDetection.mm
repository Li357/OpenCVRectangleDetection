//
//  RectangleDetection.m
//  OpenCVRectangleDetection
//
//  Created by Andrew Li on 12/29/19.
//  Copyright © 2019 Andrew Li. All rights reserved.
//

#ifdef __cplusplus

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#endif

#import <UIKit/UIKit.h>
#import "RectangleDetection.h"

@implementation RectangleDetection

+ (UIImage*)drawContours: (UIImage*)image {
    cv::Mat original;
    UIImageToMat(image, original);

    cv::Mat mat;
    original.copyTo(mat);

    cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    cv::GaussianBlur(mat, mat, cv::Size(5, 5), 0);
    cv::Canny(mat, mat, 150, 300);

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(mat, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    cv::drawContours(original, contours, -1, cv::Scalar(0, 255, 0, 255), 3);
    return MatToUIImage(original);
}

@end
