//
//  WatermarkTool.m
//  WatermarkExample
//
//  Created by 罗楚健 on 16/7/13.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LC.h"
#import "WatermarkTool.h"

#define  TIME_SCALE 1000

@interface WatermarkTool ()
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@end

@implementation WatermarkTool

- (BOOL)exportMovie {
    
    if (!self.asset) {
        NSLog(@"ERROR: has no asset !");
    }
    
    NSString *exportFilePath = LOCAL_VIDEO_PATH;
    /**
     *  函数介绍：unlink()会删除参数pathname指定的文件，文件夹处理不了。成功返回0，否则返回1。
     *  unlink()会删除参数pathname指定的文件。
     *  如果该文件名为最后连接点，但有其他进程打开了此文件，则在所有关于此文件的文件描述词皆关闭后才会删除。
     *  如果参数pathname为一符号连接，则此连接会被删除。
     *  http://www.verydemo.com/demo_c288_i37252.html
     *
     *  在此用于删除旧视频
     */
    unlink([exportFilePath UTF8String]);
    NSURL *exportURL = [NSURL fileURLWithPath:exportFilePath];
    
    AVMutableComposition *composition = self.composition;
    
    /**
     *  获取视频时间
     */
    float movieDuration = CMTimeGetSeconds(self.composition.duration);
    /**
     *  获取视频大小
     */
    CGSize videoSize = self.composition.naturalSize;
    
    CALayer *overLayer = [WatermarkTool videoWatermaskLayerWithVideoNaturalSize:videoSize videoDuration:movieDuration];
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overLayer];
    
    /**
     *  AVVideoComposition对象是对两个或多个视频轨道组合在一起的方法的一个总体描述
     *  就是配置了视频合成时的一些细节，例如渲染尺寸、缩放和帧时长等
     */
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.renderSize = self.composition.naturalSize;
    
    /**
     *  加水印的核心，使用coreAnimation的视频合成工具
     *  animationLayer必须作为根图层，videoLayer和水印图层作为子图层
     *  视频的图层会加在这里传入的videoLayer上面
     */
    videoComposition.animationTool =
    [AVVideoCompositionCoreAnimationTool
     videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    /**
     *  AVVideoCompositionInstruction：完成AVVideoComposition合成的指令的集合
     *  AVVideoComposition是由一组AVVideoCompositionInstruction对象格式定义的指令组成的
     */
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
    
    /**
     *  AVVideoCompositionLayerInstruction：用于定义对给定视频轨道应用的模糊、变形和裁剪效果
     */
    AVAssetTrack *clipVideoTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction *transformer =
    [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    
    /**
     *  视频导出
     */
    NSString *exportSize = [self getAVExportSessionRenderSizeString:self.composition.naturalSize];
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:exportSize];
    _exportSession.outputURL = exportURL;
    _exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    _exportSession.shouldOptimizeForNetworkUse = YES;
    _exportSession.videoComposition = videoComposition;
    _exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
    
    __weak typeof(self) weakSelf = self;
    [_exportSession exportAsynchronouslyWithCompletionHandler:^{
        typeof(weakSelf) strongSelf = weakSelf;
        if (_exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export success    !!");
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([strongSelf.delegate respondsToSelector:@selector(exportSuccess)]) {
                    [strongSelf.delegate exportSuccess];
                }
            });
        }
    }];
    
    return YES;
}

- (NSString *)getAVExportSessionRenderSizeString:(CGSize) rendSize
{
    NSString *avSize = AVAssetExportPresetHighestQuality;
    NSInteger width = rendSize.width;
    NSInteger height = rendSize.height;
    if ( (width == 640 && (height == 480 || height == 360) ) ||
        (height == 640 && (width == 480 || width == 360) ) )
    {
        avSize = AVAssetExportPreset640x480;
    }
    else if( (width == 960  && height == 540) ||
            (height == 960  && width == 540) )
    {
        avSize = AVAssetExportPreset960x540;
    }
    else if( (width == 1280 && height == 720) ||
            (height == 1280 && width == 720) )
    {
        avSize = AVAssetExportPreset1280x720;
    }
    else if( (width == 1920 && height == 1080) ||
            (height == 1920 && width == 1080)
            )
    {
        avSize = AVAssetExportPreset1920x1080;
    }
    NSLog(@"MVCameRollSharer: rendSize: %@", avSize);
    return avSize;
}


/**
 *  得到asset的音视频轨道，生成相应的AVMutableComposition
 *
 *  @return asset音视频的组合结构
 */
- (AVMutableComposition *)composition {
    if (_composition) {
        return _composition;
    }
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    /**
     *  判断asset是否有音视频的轨道，并获取
     */
    if ([[_asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [[_asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    if ([[_asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [[_asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    
    /**
     *  新建一个AVMutableComposition对象
     */
    _composition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        /**
         *  为composition添加一个新视频轨道，TrackID是追踪这个轨道的标示，默认填kCMPersistentTrackID_Invalid就行
         *  下面的音频轨道同理
         */
        AVMutableCompositionTrack *compositionVideoTrack =
        [_composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                  preferredTrackID:kCMPersistentTrackID_Invalid];
        /**
         *  将刚才在asset获取的视频轨道插进compositionVideoTrack中去
         *  TimeRange代表想要插入的视频资源的时间范围
         */
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [_asset duration])
                                       ofTrack:assetVideoTrack
                                        atTime:insertionPoint error:nil];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack =
        [_composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                  preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [_asset duration])
                                       ofTrack:assetAudioTrack
                                        atTime:insertionPoint error:nil];
    }
    
    return _composition;
}


/**
 *  视频水印
 *
 *  @param videoSize 视频长宽
 *  @param duration  视频总时间
 *
 *  @return 水印layer
 */
+ (CALayer *)videoWatermaskLayerWithVideoNaturalSize:(CGSize)videoSize videoDuration:(CGFloat)duration {
    
    CGRect videoFrame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    //动画过程
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation setFromValue:[NSNumber numberWithFloat:0]];
    [animation setToValue:[NSNumber numberWithFloat:1.0]];
    [animation setDuration:3.0];
    [animation setBeginTime:duration-(duration > 8 ? 8 : duration)];
    [animation setFillMode:kCAFillModeForwards];
    [animation setRemovedOnCompletion:NO];
    
    //最后出现的蒙板
    CALayer *overLayer = [CALayer layer];
    overLayer.frame = CGRectMake(0, 0, videoFrame.size.width, videoFrame.size.height);
    overLayer.opacity = 0.f;
    [overLayer addAnimation:animation forKey:@"animateOpacity"];
    
    //文字
    CATextLayer * textLayer = [CATextLayer layer];
    textLayer.string = @"我是水印";
    textLayer.fontSize = 50;
    textLayer.alignmentMode = kCAAlignmentCenter;
    [textLayer setForegroundColor:[UIColor whiteColor].CGColor];
    textLayer.frame = CGRectMake(0, 0, videoFrame.size.width, videoFrame.size.height);
    [overLayer addSublayer:textLayer];
    
    return overLayer;
}

@end
