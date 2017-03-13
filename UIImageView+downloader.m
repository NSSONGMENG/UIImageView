//
//  UIImage+downloader.m
//  Boobuz
//
//  Created by songmeng on 16/7/21.
//  Copyright © 2016年 erlinyou.com. All rights reserved.
//

#import "UIImageView+downloader.h"
#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import <objc/runtime.h>


@interface UIImageView ()

//可以使用runtime给category添加属性

/** 当前加载的图片url，保存此url用以在图片加载完毕后判断该图片是否是image view最新需要显示的图片 */
@property (nonatomic, copy) NSString * url;

/** 重复请求次数，图片请求失败后重试请求次数 */
@property (nonatomic, strong) NSNumber * repeatCount;

@end

@implementation UIImageView (downloader)

- (UIImage *)loadImageWithUrl:(NSURL *)url{
    if (![url.absoluteString containsString:@"http"]) {
        return nil;
    }
    
    self.url = url.absoluteString;
    UIImage * image = [self getCacheImageWithURL:url];
    if (!image) {
        [self loadImageWithUrl:url complete:^(UIImage *image, NSString *url1) {
            if (image && [url1 isEqualToString:self.url]) {
                self.image = image;
            }
        }];
        
//        [self sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//            [[SDWebImageManager sharedManager] saveImageToCache:image forURL:imageURL];
//        }];
    }else{
        self.image = image;
    }
    return  image;
}

- (void)loadImageWithURL:(NSURL *)url placeHolderImage:(UIImage *)img{
    self.image = img;
    if (!url || ![url.absoluteString containsString:@"http"]) {
        return;
    }
    
    self.url = url.absoluteString;
    UIImage     * cacheImg = [self getCacheImageWithURL:url];
    if (!cacheImg) {
        [self loadImageWithUrl:url complete:^(UIImage *image, NSString *url1) {
            if (image && [url1 isEqualToString:self.url]) {
                self.image = image;
            }
        }];
        
//        [self sd_setImageWithURL:url placeholderImage:img options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//            
//            if (image) {
//                [[SDWebImageManager sharedManager] saveImageToCache:image forURL:imageURL];
//            }
//        }];
    }
    else{
        self.image = cacheImg;
    }
}

- (void)loadImageWithURL:(NSURL *)url placeHolderImage:(UIImage *)placeHolderImg compete:(void(^)(UIImage *image, NSString *imageURL))complete{
    self.image = placeHolderImg;
    if (!url || ![url.absoluteString containsString:@"http"]) {
        return;
    }
    
    self.url = url.absoluteString;
    UIImage * img = [self getCacheImageWithURL:url];
    if (!img) {
        
        [self loadImageWithUrl:url complete:^(UIImage *image, NSString *url1) {
            
            if (image && [url1 isEqualToString:self.url]) {
                self.image = image;
            }
            
        }];
        
//        [self sd_setImageWithURL:url placeholderImage:placeHolderImg options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//            
//            [[SDWebImageManager sharedManager] saveImageToCache:image forURL:imageURL];
//            if (complete) {
//                complete(image,imageURL.absoluteString);
//            }
//        }];
    }
    else{
        self.image = img;
    }
}


- (void)loadImageWithURL:(NSURL *)url
                complete:(void(^)(UIImage * image, NSString * url))complete
                progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress{
    UIImage * cacheImg = [self getCacheImageWithURL:url];
    if (complete) {
        complete (cacheImg,url.absoluteString);
    }
    if (cacheImg) {
        self.image = cacheImg;
        return;
    }
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:url
                                                    options:SDWebImageRetryFailed
                                                   progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                       if (progress) {
                                                           progress(receivedSize, expectedSize);
                                                       }
                                                   } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                       if (image) {
                                                           [[SDWebImageManager sharedManager] saveImageToCache:image forURL:url];
                                                            self.image = image;
                                                       }
                                                   }];
}

/**
 通过网络请求下载并缓存图片,不会对UIImageView对象赋值
 
 @param url 图片http地址
 @param complete 完成回调
 */
- (void)loadImageWithUrl:(NSURL *)url complete:(void(^)(UIImage * image, NSString * url))complete{
    [[SDWebImageManager sharedManager] downloadImageWithURL:url
                                                    options:SDWebImageRetryFailed
                                                   progress:nil
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                       if (image) {
                                                           [[SDWebImageManager sharedManager] saveImageToCache:image forURL:url];
                                                       }
                                                      if (complete) complete(image,imageURL.absoluteString);
                                                   }];
}

- (UIImage *)getCacheImageWithURL:(NSURL *)url{
    if (![[NSString stringWithFormat:@"%@",url] containsString:@"http://"]) {
        return nil;
    }
    NSString    * cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    NSString    * imgPath = [[SDImageCache sharedImageCache] defaultCachePathForKey:cacheKey];
    BOOL exists = NO;
    
    exists = [[NSFileManager defaultManager] fileExistsAtPath:imgPath];

    if (!exists) {
        exists = [[NSFileManager defaultManager] fileExistsAtPath:[imgPath stringByDeletingPathExtension]];
    }

    if (exists) {
        UIImage     * img = [UIImage imageWithContentsOfFile:imgPath];
        return img;
    }
    return nil;
}

#pragma mark - property
//运用runtime给category添加私有属性

static NSString *urlKey = @"urlKey";
- (void)setUrl:(NSString *)url{
    objc_setAssociatedObject(self, &urlKey, url, OBJC_ASSOCIATION_COPY);
}

- (NSString *)url{
    return objc_getAssociatedObject(self, &urlKey);
}


static  NSString *repeatKey = @"repeatKey";
- (void)setRepeatCount:(NSNumber *)repeatCount{
     objc_setAssociatedObject(self, &repeatKey, repeatCount, OBJC_ASSOCIATION_RETAIN);
}

- (NSNumber *)repeatCount{
    return objc_getAssociatedObject(self, &repeatKey);
}

@end
