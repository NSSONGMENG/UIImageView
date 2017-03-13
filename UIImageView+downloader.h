//
//  UIImage+downloader.h
//  Boobuz
//
//  Created by songmeng on 16/7/21.
//  Copyright © 2016年 erlinyou.com. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 基于SD_webImage构建，避免了使用SD时每次刷新都会出现闪烁的现象。
    －图片下载完成后缓存到本地
    －加载图片时优先查询本地是否已经缓存url对应的图片
    －若未缓存，则进行网络请求去加载
    －若已经缓存，则不再请求
 */
@interface UIImageView (downloader)

/**
 加载图片,如果在磁盘中找到图片，则返回该图片,否则进行请求加载
 
 @param url 图片http地址
 @param complete 完成回调
 @param progress 加载进度
 */
- (void)loadImageWithURL:(NSURL *)url
                complete:(void(^)(UIImage * image, NSString * url))complete
                progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress;


/**
 通过网络请求下载并缓存图片,不会对UIImageView对象赋值

 @param url 图片http地址
 @param complete 完成回调
 */
- (void)loadImageWithUrl:(NSURL *)url complete:(void(^)(UIImage * image, NSString * url))complete;

/**
 加载disk中缓存的图片，未缓存则返回nil

 @param url 图片的http地址
 @return 缓存图片 ／ nil
 */
- (UIImage *)getCacheImageWithURL:(NSURL *)url;

/** 缓存中存在则返回对应图片，不存在则发起请求，返回nil。请求完成后缓存 */
- (UIImage *)loadImageWithUrl:(NSURL *)url;

/** 优先从缓存中获取，缓存中没有的话进行网络请求，得到图片后赋值 */
- (void)loadImageWithURL:(NSURL *)url placeHolderImage:(UIImage *)img;

/** 优先从缓存中获取，缓存中没有的话进行网络请求，得到图片后赋值 */
- (void)loadImageWithURL:(NSURL *)url placeHolderImage:(UIImage *)placeHolderImg compete:(void(^)(UIImage *image, NSString *imageURL))complete;

@end
