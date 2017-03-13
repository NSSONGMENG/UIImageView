//
//  SomeImageDownloader.m
//  Boobuz
//
//  Created by songmeng on 16/7/20.
//  Copyright © 2016年 erlinyou.com. All rights reserved.
//

#import "SomeImageDownloader.h"
#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import "UIButton+WebCache.h"
#import "ChatMessageModel.h"
#import "UIImage+fixOrientation.h"
#import "UIImage+Zip.h"

#define AIM_IMAGE_Width 1024

@implementation SomeImageDownloader

static SomeImageDownloader * instance;
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [SomeImageDownloader new];
    });
    return instance;
}


#pragma mark  - public method
/** 清空缓存 */
- (void)cleanCache{
    [[SDImageCache sharedImageCache] cleanDisk];
}


/**
 加载图片,有缓存的话回调缓存，无缓存网络加载
 
 @param url 图片http地址
 @param complete 如果在磁盘中找到图片，则返回该图片
 @param progress 请求下载进度
 */
- (void)loadImageWithURL:(NSURL *)url
                complete:(void(^)(UIImage * image, NSString * imgUrl))complete
                progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, NSString * imgUrl))progress{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage * chaheImg = [self getCacheImageWithURL:url];
        if (complete && chaheImg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete (chaheImg,[NSString stringWithFormat:@"%@",url]);
            });
        }

        if (chaheImg) {
            return;
        }

        [self loadImageWithURL:url
                      progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                          if (progress) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  progress(receivedSize,expectedSize,url.absoluteString);
                              });
                          }
                      } complete:^(UIImage *image) {
                          if (complete) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  complete(image,[NSString stringWithFormat:@"%@",url]);
                              });
                          }
                      }];
    });
}

/** 获取缓存的图片 */
- (UIImage *)getCacheImageWithURL:(NSURL *)url{
    if (url == nil) {
        return nil;
    }
    BOOL    exist = [[SDWebImageManager sharedManager] diskImageExistsForURL:url];
    if (exist) {
        NSString    * cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
        if (cacheKey.length > 0){
            NSString    * imgPath = [[SDImageCache sharedImageCache] defaultCachePathForKey:cacheKey];
            NSData      * imgData = [NSData dataWithContentsOfFile:imgPath];
            if (imgData) {
                UIImage     * img = [UIImage imageWithData:imgData];
                return img;
            }
        }
    }

    return nil;
}


/** 网络请求并缓存 */
- (void)loadImageWithURL:(NSURL *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress complete:(void(^)(UIImage * image))complete{
    [[SDWebImageManager sharedManager]downloadImageWithURL:url
                                                   options:SDWebImageRefreshCached
                                                  progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                      if (progress) {
                                                          progress(receivedSize,expectedSize);
                                                      }
                                                  } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                      if (complete) {
                                                          complete(image);
                                                      }
                                                      if (image) {
                                                          [[SDWebImageManager sharedManager] saveImageToCache:image forURL:url];
                                                      }
                                                  }];
}

/**
 根据URL数组获取图片数组
 
 @param urls http地址，NSString／NSURL
 @param complete images回调
 */
- (void)getImageWithUrls:(NSArray *)urls complete:(void(^)(NSArray *imgs))complete;{
    __block NSMutableArray * urlArr = [@[] mutableCopy];
    [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [urlArr addObject:[NSURL URLWithString:(NSString *)obj]];
        }else if ([obj isKindOfClass:[NSURL class]]){
            [urlArr addObject:obj];
        }
    }];

    //获取缓存图片
    __block NSMutableArray  * imageArray = [NSMutableArray array];
    __block NSMutableArray  * notExistArray = [NSMutableArray array];

    [urlArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image = [self getCacheImageWithURL:(NSURL *)obj];
        if (image != nil) {
            [imageArray addObject:image];
        }else{
            [notExistArray addObject:obj];
        }
    }];

    //第一次回调处理
    if ([notExistArray count] == 0) {
        if (complete) {
            complete(imageArray);
            return;
        }
    }else{
        NSMutableArray  * imgs = [NSMutableArray arrayWithArray:imageArray];
        for (int i = 0;i < [notExistArray count]; i ++) {
            UIImage * img = [UIColor createImageWithColor:[UIColor clearColor]];
            [imgs addObject:img];
        }
        if ([imgs count] == [urls count] &&
            complete) {
            complete(imgs);
        }
    }

    //请求不存在的图片
    dispatch_group_t    group = dispatch_group_create();
    for (int i = 0; i < [notExistArray count]; i ++) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL * url = [notExistArray objectAtIndex:i];
            [self loadImageWithURL:url progress:nil complete:^(UIImage *image) {
                if (image){
                    [imageArray addObject:image];
                }else{
                    [imageArray addObject:[UIColor createImageWithColor:[UIColor lightGrayColor]]];
                }
            }];
        });
    }

    //第二次回调
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (complete) {
            complete(imageArray);
        }
    });
}

/**
 根据PHasset获取图片数组
 
 @param assets PHAsset数组
 @param complete images数组
 */
- (void)getImageWithAssets:(NSArray *)assets complete:(void(^)(NSArray *imgs))complete{
    __block NSMutableArray  * imges = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();

    for (int i = 0; i < [assets count]; i ++) {
        [imges addObject:@""];
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger   index = i;
            id obj = [assets objectAtIndex:i];
            if ([obj isKindOfClass:[PHAsset class]]) {
                PHAsset * set = obj;

                CGSize size;
                if (set.pixelWidth < AIM_IMAGE_Width) {
                    size = CGSizeMake(set.pixelWidth, set.pixelHeight);
                }else{
                    size = CGSizeMake(AIM_IMAGE_Width, AIM_IMAGE_Width*set.pixelHeight/set.pixelWidth);
                }

                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                option.synchronous = YES;
                option.resizeMode = PHImageRequestOptionsResizeModeExact;
                option.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;

                [[PHImageManager defaultManager] requestImageForAsset:set targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    result = [UIImage fixOrientation:result];
                    
                    NSData  * imageData = [UIImage compressImageWithImage:result aimWidth:AIM_IMAGE_Width aimLength:70*1024 accuracyOfLength:5*1024];
                    if (imageData) {
                        [imges replaceObjectAtIndex:index withObject:imageData];
                    }
                }];
            }else if([obj isKindOfClass:[NSString class]] && ![(NSString *)obj containsString:@"mp4"]){
                PHAsset * asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[obj] options:nil] firstObject];
                if (!asset) {
                    return;
                }

                CGSize size;
                if (asset.pixelWidth < AIM_IMAGE_Width) {
                    size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
                }else{
                    size = CGSizeMake(AIM_IMAGE_Width, AIM_IMAGE_Width*asset.pixelHeight/asset.pixelWidth);
                }

                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                option.synchronous = YES;
                option.resizeMode = PHImageRequestOptionsResizeModeExact;
                option.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;

                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    result = [UIImage fixOrientation:result];
                    NSData  * imageData = [UIImage compressImageWithImage:result aimWidth:AIM_IMAGE_Width aimLength:70*1024 accuracyOfLength:5*1024];
                    if (imageData) {
                        [imges replaceObjectAtIndex:index withObject:imageData];
                    }
                }];
            }else if([obj isKindOfClass:[NSString class]] && [(NSString *)obj containsString:@"var/"]){
                obj = [[obj componentsSeparatedByString:@"/"] lastObject];
                ChatMessageModel * model = [ChatMessageModel new];
                model.contentType = chatContentTypeVideo;
                NSString * path = [model getFileDocumentPath];
                path = [path stringByAppendingString:obj];
                [imges replaceObjectAtIndex:index withObject:path];
            }else{
                DLog(@" video path : %@",obj);
                [imges replaceObjectAtIndex:index withObject:obj];
            }
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (complete) {
            complete(imges);
        }
    });
}

/**
 根据图片的local id获取PHAsset对象（参数数组中的AttachmentPhoto（自定义图片类）对象和视频本地地址不作处理，按原样返回）
 
 @param idents 待处理数组
 @return 目标数组
 */
- (NSArray *)getPhassetObjsWithLocalIdents:(NSArray *)idents{
    NSMutableArray  * aimArr = [NSMutableArray array];
    [idents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]] && ![(NSString *)obj containsString:@"mp4"]) {
            NSString    * photoId = obj;
            PHAsset * asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[photoId] options:nil] firstObject];
            [aimArr addObject:asset];
        }else{
            [aimArr addObject:obj];
        }
    }];
    return [aimArr copy];
}

@end
