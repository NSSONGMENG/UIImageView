//
//  UIImage+RoundImage.m
//  Boobuz
//
//  Created by KongPeng on 16/12/16.
//  Copyright © 2016年 erlinyou.com. All rights reserved.
//

#import "UIImage+RoundImage.h"
#import "UIImage+Zip.h"

@implementation UIImage (RoundImage)

- (UIImage *)roundImage
{
    UIColor *borderColor;
    UIColor *fillColor;
    if ([DKNightVersionManager currentThemeVersion] == DKThemeVersionNormal) {
        borderColor = [UIColor erlinyouNightBackgroundColor];
        fillColor = [UIColor erlinyouWhiteColor];
    }else{
        borderColor = [UIColor erlinyouWhiteColor];
        fillColor = [UIColor erlinyouNightBackgroundColor];
    }
    
    CGImageRef  image_cg = [self CGImage];
    CGSize      imageSize = CGSizeMake(CGImageGetWidth(image_cg), CGImageGetHeight(image_cg));
    
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    
    CGFloat width;
    CGPoint purePoint;
    if (imageWidth > imageHeight){
        width = imageHeight;
        purePoint = CGPointMake((imageWidth - width) / 2, 0);
    }else{
        width = imageWidth;
        purePoint = CGPointMake(0, (imageHeight - width) / 2);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image_cg, CGRectMake(purePoint.x, purePoint.y, width, width));
    UIImage * thumbImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    
    // borderWidth 表示边框的宽度
    CGFloat imageW = width + 2 * HEADERIMAGE_BORDER_WIDTH;
    CGFloat imageH = imageW;
    imageSize = CGSizeMake(imageW, imageH);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat bigRadius = imageW * 0.5;
    CGFloat centerX = imageSize.width/2;
    CGFloat centerY = imageSize.height/2;
    CGContextAddArc(context, centerX, centerY, bigRadius, 0, M_PI * 2, 0);
    CGContextSetFillColorWithColor(context, borderColor.CGColor);
    CGContextFillPath(context);
    CGFloat smallRadius = bigRadius - HEADERIMAGE_BORDER_WIDTH*2;
    CGContextAddArc(context, centerX, centerY, smallRadius, 0, M_PI * 2, 0);
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextFillPath(context);
    
    CGContextAddArc(context, centerX, centerY, smallRadius, 0, M_PI * 2, 0);
    CGContextClip(context);
    
    [thumbImage drawInRect:CGRectMake(HEADERIMAGE_BORDER_WIDTH, HEADERIMAGE_BORDER_WIDTH, imageW, imageW)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
