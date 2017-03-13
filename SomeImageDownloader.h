//
//  SomeImageDownloader.h
//  Boobuz
//
//  Created by songmeng on 16/7/20.
//  Copyright © 2016年 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


/**
 此类是基于SDWebImage实现，主要功能包括图片请求、缓存以及从缓存中读取图片，并提供了清空缓存方法
 附加功能实现了通过PHAsset从本地相册获取图片以及根据PHAsset的local id获取PHAsset对象的方法
 */
@interface SomeImageDownloader : NSObject

+ (instancetype)shareInstance;

#pragma mark - api
/** 清空缓存 */
- (void)cleanCache;

/**
 加载图片,有缓存的话回调缓存，无缓存网络加载

 @param url 图片http地址
 @param complete 如果在磁盘中找到图片，则返回该图片
 @param progress 请求下载进度
 */
- (void)loadImageWithURL:(NSURL *)url
                complete:(void(^)(UIImage * image, NSString * imgUrl))complete
                progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, NSString * imgUrl))progress;

/**
 加载disk中缓存的图片，未缓存则返回nil

 @param url 图片的http地址
 @return 缓存图片
 */
- (UIImage *)getCacheImageWithURL:(NSURL *)url;

/**
 根据URL数组获取图片数组

 @param urls http地址，NSString／NSURL
 @param complete images回调
 */
- (void)getImageWithUrls:(NSArray *)urls complete:(void(^)(NSArray *imgs))complete;

/**
 根据PHasset获取图片数组

 @param assets PHAsset数组
 @param complete images数组
 */
- (void)getImageWithAssets:(NSArray *)assets complete:(void(^)(NSArray *imgs))complete;

/**
 根据图片的local id获取PHAsset对象（参数数组中的AttachmentPhoto（自定义图片类）对象和视频本地地址不作处理，按原样返回）

 @param idents 待处理数组
 @return 目标数组
 */
- (NSArray *)getPhassetObjsWithLocalIdents:(NSArray *)idents;

@end
