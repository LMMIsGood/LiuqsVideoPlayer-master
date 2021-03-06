//
//  LiuqsVideoPlayer.m
//  LiuqsVideoPlayerDemo
//
//  Created by 刘全水 on 16/7/12.
//  Copyright © 2016年 刘全水. All rights reserved.
//

#import "LiuqsVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "BrightnessView.h"
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
//视频比例
#define PlayerHeight SCREEN_WIDTH * 9 / 16
//当前的播放状态
typedef enum : NSUInteger {
    
    currentModelPlayIng   = 0,
    currentModelPasue     = 1,
    currentModelBufferIng = 2,
    currentModelStop      = 3,
    
} currentModel;

//手势的方向
typedef NS_ENUM(NSInteger, PanDirection) {
    // 横向移动
    PanDirectionHorizontalMoved,
    // 纵向移动
    PanDirectionVerticalMoved
};

@interface LiuqsVideoPlayer ()<UIGestureRecognizerDelegate>

//播放器
@property(nonatomic, strong)AVPlayer             *player;
//播放器layer
@property(nonatomic, strong)AVPlayerLayer        *playerLayer;
//用来保存快进的总时长
@property(nonatomic, assign)CGFloat              sumTime;
//是否在调节音量
@property(nonatomic, assign)BOOL                 isVolume;
//网速定时器
@property(nonatomic,strong)NSTimer               *rateTimer;
//当前状态
@property(nonatomic, assign)currentModel         currentModel;
//滑动方向
@property(nonatomic, assign)PanDirection         panDirection;
// 播放属性
@property(nonatomic, strong)AVPlayerItem         *playerItem;
//音量
@property(nonatomic, strong)UISlider             *volumeViewSlider;
//slider上次的值
@property(nonatomic, assign)CGFloat              sliderLastValue;
//初始化播放器
@property(nonatomic, assign)BOOL                 isInitPlayer;
//播放进度监听
@property(nonatomic, strong)id                   timeObserve;
//播放结束
@property(nonatomic, assign)BOOL                 isPlayEnd;
//第一次加载失败
@property(nonatomic, assign)BOOL                 isFirstFail;
//上一次的下行流量
@property(nonatomic, assign)long long int        lastBytes;
//监听收到电话
@property (nonatomic, strong)CTCallCenter        *callCenter;

@end

@implementation LiuqsVideoPlayer


- (void)pasue {

    [self pasueBtnClick:nil];
}

- (void)play {

    [self PlayBtnClick:nil];
}

- (void)playerPlay {

    [self.player play];
}

- (void)playerPause {

    [self.player pause];
}

- (void)setVideoURL:(NSURL *)videoURL {          
    
    _videoURL = videoURL;
    [self initPlayer];
    [self addControlActions];
    [self ListeningDeviveRotating];
    [self addNoticationsAndObservers];
    [self addTellEvent];
}


- (instancetype)init {

    if (self = [super init]) {
        
        [self initProperty];
    }
    return self;
}

- (void)initProperty {
    
    self.isAutoPlay   = YES;
    self.isLocalTask  = NO;
    self.isFirstFail  = YES;
    self.isAllowPlay  = YES;
}

- (void)resetPlayerWithUrl:(NSURL *)VideoUrl {

    if (VideoUrl) {_videoURL = VideoUrl;}
    self.isAutoPlay = YES;
    [self resetPlayer];
    [self initPlayer];
    [self addControlActions];
    [self ListeningDeviveRotating];
    [self addNoticationsAndObservers];
}

- (void)setCurrentModel:(currentModel)currentModel {
    
    _currentModel = currentModel;
    //修改加载视图的状态
    if (currentModel == currentModelPasue || currentModel == currentModelPlayIng || currentModel == currentModelStop) {
        
        [self.playerControl dissmissLoadingView];
    }else {
        if (!self.isLocalTask && ![[UserDefaults objectForKey:@"netWork"] isEqualToString:@"offline"]) {
            
            [self.playerControl showLoadingView];
        }
    }
    //修改播放和暂停按钮的状态
    if (self.currentModel == currentModelPlayIng) {
        self.playerControl.pauseBtn.hidden = NO;
        self.playerControl.playBtn.hidden  = YES;
    }else {
    
        self.playerControl.pauseBtn.hidden = YES;
        self.playerControl.playBtn.hidden  = NO;
    }
}

- (void)setVideoSize:(NSString *)VideoSize {

    _VideoSize = VideoSize;
    self.playerControl.sizeLabel.text = VideoSize;
}


- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    
    if (_playerItem == playerItem) {return;}
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PlayEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

//监听电话
- (void)addTellEvent {

    if (!self.callCenter) {
        
        self.callCenter = [[CTCallCenter alloc] init];
        
        __weak typeof(self) weakSelf = self;
        self.callCenter.callEventHandler = ^(CTCall* call) {
            
            [weakSelf pasue];
            
            if ([call.callState isEqualToString:CTCallStateDisconnected]) {
                
                NSLog(@"挂断了电话");
            }else if ([call.callState isEqualToString:CTCallStateConnected]) {
                
                NSLog(@"电话通了");
            }else if([call.callState isEqualToString:CTCallStateIncoming]) {
                
                NSLog(@"来电话了");
                                 
            }else if ([call.callState isEqualToString:CTCallStateDialing]) {
                
                NSLog(@"正在播出电话");
            }else {
                
                NSLog(@"啥都没做");
            }
        };
    }
}

- (void)initPlayer {
    //控制视图
    [self initPlayControlView];
    // 获取系统音量
    [self configureVolume];
    if (self.isAutoPlay) {
        [self configurePlayer];
    }else {
        self.isInitPlayer = NO;
        self.playerControl.pauseBtn.hidden = YES;
        self.playerControl.playBtn.hidden = NO;
    }
    //事件block
    [self addBlockEvents];
}

- (void)initPlayControlView {

    self.backgroundColor     = [UIColor blackColor];
    self.isFullScreenMode    = NO;
    [self.playerControl removeFromSuperview];
    self.playerControl       = [[LiuqsPlayControlView alloc]init];
    self.playerControl.isPlayerVCView = self.isPlayerVCView;
    [self addSubview:self.playerControl];
}

- (void)setVideoName:(NSString *)videoName {

    _videoName = videoName;
    self.playerControl.nameLabel.text = videoName;
}

- (void)addBlockEvents {

    __weak LiuqsVideoPlayer *BlockSelf = self;
    self.playerControl.animationShow = ^{
        
        if (BlockSelf.PayerControlAnimationShow) {
            BlockSelf.PayerControlAnimationShow();
        }
    };
    self.playerControl.animationHide = ^{
        
        if (BlockSelf.PayerControlAnimationHide) {
            BlockSelf.PayerControlAnimationHide();
        }
    };
}

- (void)resetPlayer {
    
    [self.playerControl removeFromSuperview];
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    self.playerItem = nil;
    [self.rateTimer invalidate];
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
}

- (void)configurePlayer {
    
    if ([[UserDefaults objectForKey:@"netWork"] isEqualToString:@"offline"] && !self.isLocalTask) {
        
        NSLog(@"网络连接已断开");
        self.currentModel = currentModelStop;
        
    }else {
        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:self.videoURL];
        // 初始化playerItem
        self.playerItem      = [AVPlayerItem playerItemWithAsset:urlAsset];
        self.player          = [AVPlayer playerWithPlayerItem:self.playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        self.playerLayer     = playerLayer;
        self.playerControl.PlaceHoderView.hidden = YES;
        [BrightnessView sharedBrightnessView];
        playerLayer.videoGravity  = AVLayerVideoGravityResizeAspect;
        [self.layer insertSublayer:playerLayer atIndex:0];
        self.isInitPlayer = YES;
        [self startTimers];
        self.playerControl.sizeLabel.text = self.VideoSize;
        self.currentModel = currentModelBufferIng;
    }
}

- (void)layoutSubviews {
    
    self.playerControl.frame = self.bounds;
    self.playerLayer.frame   = self.bounds;
}

- (void)configureVolume {
    
    MPVolumeView *volumeView  = [[MPVolumeView alloc] init];
    _volumeViewSlider         = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            
            _volumeViewSlider = (UISlider *)view;break;
        }
    }
    //可在手机静音下播放声音
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            // 耳机拔掉暂停
            [self pasue];
        } break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

- (void)startTimers {
    
    [self setPlayProgress];
    self.rateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(getByteRate) userInfo:nil repeats:YES];
}


- (void)setPlayProgress {
    
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            
            if (weakSelf.playerControl.PlaceHoderView.hidden == NO) {
                weakSelf.playerControl.PlaceHoderView.hidden = YES;
            }
            NSInteger currentTime                       = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            // 当前时长进度progress
            NSInteger proMin                            = currentTime / 60;//当前秒
            NSInteger proSec                            = currentTime % 60;//当前分钟
            CGFloat totalTime                           = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            // duration 总时长
            NSInteger durMin                            = (NSInteger)totalTime / 60;//总秒
            NSInteger durSec                            = (NSInteger)totalTime % 60;//总分钟
            // 更新slider
            weakSelf.playerControl.PlaySliderView.value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            // 更新当前播放时间
            NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
            NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
            weakSelf.playerControl.rightTimeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTimeStr,totalTimeStr];
        }}];
}

- (void)addControlActions {
    
    [self.playerControl.playBtn         addTarget:self action:@selector(PlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerControl.pauseBtn        addTarget:self action:@selector(pasueBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerControl.fullScreenBtn   addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerControl.shrinkScreenBtn addTarget:self action:@selector(shrinkScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    // slider开始滑动事件
    [self.playerControl.PlaySliderView  addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    // slider滑动中事件
    [self.playerControl.PlaySliderView  addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    // slider结束滑动事件
    [self.playerControl.PlaySliderView  addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    //返回按钮事件
    [self.playerControl.backBtn         addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //重试按钮
    [self.playerControl.failView.reLoadBtn addTarget:self action:@selector(reLoadVideo) forControlEvents:UIControlEventTouchUpInside];
}

- (void)reLoadVideo {

    if ([[UserDefaults objectForKey:@"netWork"] isEqualToString:@"offline"] && !self.isLocalTask) {
        NSLog(@"网络连接已断开");
    }else {

        if (self.videoURL) {
            self.playerControl.failView.hidden = YES;
            [self resetPlayerWithUrl:nil];
        }else {
        
            if (self.requestVideoInfoBlock) {
                self.requestVideoInfoBlock();
            }
        }
    }
}

- (void)progressSliderTouchBegan:(UISlider *)slider {
    
    if (!self.isInitPlayer) {[self configurePlayer];}
    [self.player pause];
    self.currentModel = currentModelPasue;
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        if (self.playerItem.isPlaybackLikelyToKeepUp) {
            self.currentModel = currentModelPlayIng;
        }else {
            self.currentModel = currentModelBufferIng;
        }
        // 视频总时间长度
        CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * slider.value);
        [self seekToTime:dragedSeconds completionHandler:nil];
    }
}

- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // seekTime:completionHandler:不能精确定位
        // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        [self.player seekToTime:dragedCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            [self.player play];
        }];
    }
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    
    //拖动改变视频播放进度
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        NSString *style = @"";
        CGFloat value   = slider.value - self.sliderLastValue;
        if (value > 0) { style = @">>"; }
        if (value < 0) { style = @"<<"; }
        self.sliderLastValue = slider.value;
        // 暂停
        [self.player pause];
        CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * slider.value);
        //转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime  = CMTimeMake(dragedSeconds, 1);
        // 拖拽的时长
        NSInteger proMin = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟
        //duration 总时长
        NSInteger durMin = (NSInteger)total / 60;//总秒
        NSInteger durSec = (NSInteger)total % 60;//总分钟
        NSString *currentTime = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        NSString *totalTime   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
        
        if (total > 0) {
            //改变时间
            self.playerControl.rightTimeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
        }else {
            // 此时设置slider值为0
            slider.value = 0;
        }
    }else { // player状态加载失败
        // 此时设置slider值为0
        slider.value = 0;
    }
}

//注册通知和监听
- (void)addNoticationsAndObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MobileChanged:) name:@"MobileChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(EnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)EnterBackground {
    
    [self pasue];
}

- (void)MobileChanged:(NSNotification *)noti {
    
    [self resetPlayer];
    [self removeFromSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (!self.isLocalTask) {
        
        [self addNetWorkObbsever];
    }
    if (object == self.player.currentItem) {
        
        if ([keyPath isEqualToString:@"status"]) {
            
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                //添加滑动手势
                [self addPanGesture];
                
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
               //加载失败处理
                [self videoLoadFail];
            }
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            //缓冲处理
            [self playerIsBufferIng];
            
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            //播放状态处理进度
            [self loadedTimeRanges];
            
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //处理缓冲完成
            [self playerIsBuffered];
        }
    }
}

- (void)addNetWorkObbsever {

    if ([[UserDefaults objectForKey:@"netWork"] isEqualToString:@"offline"] && !self.isLocalTask && !self.playerItem.isPlaybackLikelyToKeepUp) {
        NSLog(@"网络连接已断开");
        self.currentModel = currentModelPasue;
        return;
    }else {
        
    }
}
- (void)loadedTimeRanges {

    if (self.currentModel != currentModelStop) {
        // 计算缓冲进度
        CGFloat value = [self getMovieBuffer];
        self.playerControl.cacheProgressView.progress = value / CMTimeGetSeconds(self.playerItem.duration);
        if ((self.playerControl.BottomProgressView.progress-self.playerControl.PlaySliderView.value > 0.05)) { [self play];
        }
    }
}

- (void)videoLoadFail {

    if (self.isFirstFail) {
        [self reLoadVideo];
        self.isFirstFail = NO;
    }else {
        self.playerControl.failView.hidden      = NO;
        self.playerControl.pauseBtn.hidden      = YES;
        self.playerControl.playBtn.hidden       = NO;
        self.currentModel = currentModelStop;
    }
}

- (void)playerIsBufferIng {
    
    NSLog(@"正在缓冲········");
    // 当缓冲是空的时候
    self.currentModel = currentModelBufferIng;
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    self.playerControl.playBtn.hidden  = NO;
    self.playerControl.pauseBtn.hidden = YES;
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.currentModel != currentModelPasue) {
            isBuffering = NO;
            return;
        }
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) { [self playerIsBufferIng]; }
    });
}

- (void)playerIsBuffered {
    
    NSLog(@"缓冲完成");
    // 当缓冲好的时候
    if (self.currentModel != currentModelPasue && self.currentModel != currentModelStop && self.playerItem.playbackLikelyToKeepUp) {
        [self.player play];
        self.playerControl.playBtn.hidden  = YES;
        self.playerControl.pauseBtn.hidden = NO;
        self.currentModel = currentModelPlayIng;
    }
}

- (void)addPanGesture{

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    pan.delegate = self;
    [self.playerControl addGestureRecognizer:pan];
}

//播放结束事件
- (void)PlayEnd {
    
    self.isPlayEnd = YES;
    self.playerControl.pauseBtn.hidden = YES;
    self.playerControl.playBtn.hidden  = NO;
    [self.player seekToTime:CMTimeMake(0, 1)];
    self.playerControl.PlaySliderView.value = 0.0f;
    self.playerControl.BottomProgressView.progress = 0.0f;
    self.currentModel = currentModelStop;
    if (self.LiuqsPlayerPlayEndBlock) {
        self.LiuqsPlayerPlayEndBlock();
    }
}

//播放按钮事件
- (void)PlayBtnClick:(UIButton *)playBtn {
    
    if (self.videoURL) {
      
        if (!self.isLocalTask) {
            [self addNetWorkObbsever];
        }
        if (!self.isInitPlayer){[self resetPlayerWithUrl:nil];}
        
        if (self.playerItem.isPlaybackLikelyToKeepUp) {
            
            [self.player play];
            self.currentModel = currentModelPlayIng;
            if (self.LiuqsPlayerPlayBlock) {
                self.LiuqsPlayerPlayBlock();
            }
        }
    }else {
    
        self.playerControl.failView.hidden = NO;
    }
    
    if (!self.playerControl.PlaceHoderView.hidden) {
        self.playerControl.PlaceHoderView.hidden = YES;
    }
}

//暂停按钮事件
- (void)pasueBtnClick:(UIButton *)pasueBtn {
    
    [self.player pause];
    self.currentModel = currentModelPasue;
    if (self.LiuqsPlayerPasueBlock) {
        self.LiuqsPlayerPasueBlock();
    }
}

//全屏按钮事件
- (void)fullScreenBtnClick:(UIButton *)fullScreenBtn {
    
    [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
    if (self.LiuqsPlayerFullScreenBlock) {
        self.LiuqsPlayerFullScreenBlock();
    }
}


//退出全屏按钮事件
- (void)shrinkScreenBtnClick:(UIButton *)shrinkBtn {
    
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
    if (self.LiuqsPlayerShrinkScreenBlock) {
        self.LiuqsPlayerShrinkScreenBlock();
    }
}

//返回按钮事件
- (void)backBtnClick:(UIButton *)backBtn {
    
    if (self.isFullScreenMode) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }else {
        if (self.LiuqsPlayerBackBlock) {
            self.LiuqsPlayerBackBlock();
        }
    }
    
}

//强制屏幕转屏
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        // 从2开始是因为0 1 两个参数已经被selector和target占用
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
        [self setDeviceOrientationLandscapeRight];
        
    }else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
        [self backOrientationPortrait];
    }
}

//监听设备旋转
- (void)ListeningDeviveRotating {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

// 设备旋转事件
- (void)onDeviceOrientationChange {
    
    UIDeviceOrientation oriention = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOriention = (UIInterfaceOrientation)oriention;
    switch (interfaceOriention) {
            //方向位置
        case UIInterfaceOrientationUnknown:
            break;
        case UIInterfaceOrientationPortrait:
            //返回小屏幕
            [self backOrientationPortrait];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            //返回小屏幕（倒置这种情况不处理）
            break;
        case UIInterfaceOrientationLandscapeLeft:
            //状态栏在左
            [self setDeviceOrientationLandscapeLeft];
            break;
        case UIInterfaceOrientationLandscapeRight:
            //状态栏在右
            [self setDeviceOrientationLandscapeRight];
            break;
        default:
            break;
    }
}

- (void)setIsFullScreenMode:(BOOL)isFullScreenMode {

    _isFullScreenMode = isFullScreenMode;
    
    if (isFullScreenMode) {
        //改变按钮状态
        self.playerControl.fullScreenBtn.hidden = YES;
        self.playerControl.shrinkScreenBtn.hidden = NO;
    }else {
    
        //改变按钮状态
        self.playerControl.fullScreenBtn.hidden = NO;
        self.playerControl.shrinkScreenBtn.hidden = YES;
    }
}

//全屏状态栏在右
- (void)setDeviceOrientationLandscapeRight {
    
    if (self.isFullScreenMode) {
        //是全屏模式就返回
        return;
    }else {
        
        self.playerControl.isLectureSharkMode = NO;
        [self.playerControl animateHide];
        self.isFullScreenMode = YES;
        //旋转屏调整frame
        [UIView animateWithDuration:0.3f animations:^{
            
            [self.playerControl setFrame:self.bounds];
            [self.playerLayer setFrame:self.bounds];
            
        } completion:^(BOOL finished) {
        }];
        if (self.LiuqsPlayerFullScreenBlock) {
            self.LiuqsPlayerFullScreenBlock();
        }
    }
}
//全屏状态栏在左
- (void)setDeviceOrientationLandscapeLeft {
    
    if (self.isFullScreenMode) {
        //是全屏模式就返回
        return;
    }else {
        
        self.playerControl.isLectureSharkMode = NO;
        [self.playerControl animateHide];
        //旋转屏调整frame
        self.isFullScreenMode = YES;
        [UIView animateWithDuration:0.3f animations:^{
            [self.playerControl setFrame:self.bounds];
            [self.playerLayer setFrame:self.bounds];
        } completion:^(BOOL finished) {
        }];
        if (self.LiuqsPlayerFullScreenBlock) {
            self.LiuqsPlayerFullScreenBlock();
        }
    }
}

//返回小屏幕
- (void)backOrientationPortrait {
    
    if (!self.isFullScreenMode) {
        //不是全屏模式就返回
        return;
    }else {
        
        self.playerControl.isLectureSharkMode = YES;
        [self.playerControl animateShow];
        self.isFullScreenMode = NO;
        [UIView animateWithDuration:0.3f animations:^{
            //旋转屏调整frame
            [self.playerControl setFrame:self.bounds];
            [self.playerLayer setFrame:CGRectMake(0, (self.frame.size.height - PlayerHeight) / 2, SCREEN_WIDTH, PlayerHeight)];
            
        } completion:^(BOOL finished) {
        }];
        if (self.LiuqsPlayerShrinkScreenBlock) {
            self.LiuqsPlayerShrinkScreenBlock();
        }
    }
}

#pragma mark - 手势事件
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self.playerControl];
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self.playerControl];
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.playerControl.horizontalLabel.hidden = NO;
                self.panDirection = PanDirectionHorizontalMoved;
                self.currentModel = currentModelPasue;
                // 给sumTime初值
                CMTime time = self.player.currentTime;
                self.sumTime = time.value/time.timescale;
                // 暂停视频播放
                [self.player pause];
                // 暂停timer
            }
            else if (x < y){
                // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.playerControl.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else {
                    // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                
                    // 继续播放
                    if (self.playerItem.isPlaybackLikelyToKeepUp) {
                        [self.player play];
                        self.currentModel = currentModelPlayIng;
                    }else {
                    
                        self.currentModel = currentModelBufferIng;
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // 隐藏视图
                        self.playerControl.horizontalLabel.hidden = YES;
                    });
                    
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.playerControl.horizontalLabel.hidden = YES;
                    });
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)horizontalMoved:(CGFloat)value {
    
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) { style = @"<<"; }
    if (value > 0) { style = @">>"; }
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    // 需要限定sumTime的范围
    CMTime totalTime = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration){
        self.sumTime = totalMovieDuration;
    }
    if (self.sumTime < 0){
        self.sumTime = 0;
    }
    // 当前快进的时间
    NSString *nowTime = [self durationStringWithTime:(int)self.sumTime];
    // 给label赋值
    self.playerControl.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@",style, nowTime];
}

- (void)verticalMoved:(CGFloat)value {
    
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

- (NSString *)durationStringWithTime:(int)time {
    
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    CGPoint point = [touch locationInView:self.playerControl];
    // （屏幕下方slider区域不可以滑动）
    if ((point.y > self.playerControl.bounds.size.height - 40)){
        
        return NO;
    }
    return YES;
}

// 获取视频缓冲进度
- (NSTimeInterval)getMovieBuffer {
    
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    // 获取缓冲区
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    // 缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

- (void)dealloc {
    
    NSLog(@"播放器被释放了");
    [self resetPlayer];
}


//获取下行速度
- (void)getByteRate {
    
    long long int rate;
    long long int currentBytes = [self getInterfaceBytes];
    if (self.lastBytes) {
        //用上当前的下行总流量减去上一秒的下行流量达到下行速录
        rate = currentBytes - self.lastBytes;
    }
    if (currentBytes) {
        //保存上一秒的下行总流量
        self.lastBytes = currentBytes;
    }
    //格式化一下
    NSString *rateStr = [self formatNetWork:rate];
    self.playerControl.LoadingView.rateLabel.text = [NSString stringWithFormat:@"%@",rateStr];
}

//获取数据流量详情
- (long long int)getInterfaceBytes {
    
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1) {
        
        return 0;
    }
    uint32_t iBytes = 0;
    uint32_t oBytes = 0;
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        
        if (AF_LINK != ifa->ifa_addr->sa_family)
            
            continue;
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            
            continue;
        if (ifa->ifa_data == 0)
            
            continue;
        if (strncmp(ifa->ifa_name, "lo", 2)) {
        
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
        }
    }
    freeifaddrs(ifa_list);
    //返回下行的总流量
    return iBytes;
}

- (NSString *)formatNetWork:(long long int)rate {

    if (rate < 1024) {
        
        return [NSString stringWithFormat:@"%lldB/秒", rate];
    }else if(rate >= 1024 && rate < 1024 * 1024) {
        
        return [NSString stringWithFormat:@"%.1fKB/秒", (double)rate / 1024];
    }else if (rate >= 1024 * 1024 && rate < 1024 * 1024 * 1024){

    return [NSString stringWithFormat:@"%.2fMB/秒", (double)rate / (1024 * 1024)];
    }else {
        return @"0B/秒";
    };
}


@end
