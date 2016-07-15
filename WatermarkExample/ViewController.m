//
//  ViewController.m
//  WatermarkExample
//
//  Created by 罗楚健 on 16/7/13.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LC.h"
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <WatermarkToolDelegate>
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UIButton *playButton;
@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    NSString *videoURL = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
    AVAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoURL]];
    /**
     *  加水印
     */
    WatermarkTool *tool = [[WatermarkTool alloc] init];
    tool.asset = asset;
    tool.delegate = self;
    [tool exportMovie];
}

- (void)setupUI {
    self.playButton = [[UIButton alloc] init];
    _playButton.frame = CGRectMake((SCREEN_WIDTH-90)/2, SCREEN_WIDTH+50, 90, 45);
    [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    [_playButton setTitle:@"暂停" forState:UIControlStateSelected];
    [_playButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(onPlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    _playButton.enabled = NO;
    [self.view addSubview:_playButton];
    
    // playerView
    self.playerView = [[UIView alloc] init];
    _playerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
    [self.view addSubview:_playerView];

}

- (void)onPlayButtonClicked:(UIButton *)sender {
    if (_player) {
        if (_player.rate == 0) {
            [_player play];
            sender.selected = YES;
        } else {
            [_player pause];
            sender.selected = NO;
        }
    }
}


/**
 *  视频结束调用
 */
- (void)playEnd {
    [_player seekToTime:CMTimeMake(0, 100)];
    _playButton.selected = NO;
}

#pragma mark - WatermarkToolDelegate
- (void)exportSuccess {
    NSString *videoURL = LOCAL_VIDEO_PATH;
    AVAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoURL]];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    _playButton.enabled = YES;
    
    if (_player) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.frame = _playerView.layer.bounds;
        [_playerView.layer addSublayer:_playerLayer];
    }
}

@end
