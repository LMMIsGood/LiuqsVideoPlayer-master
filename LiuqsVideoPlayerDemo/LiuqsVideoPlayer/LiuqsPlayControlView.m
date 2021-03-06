//
//  LiuqsPlayerControl.m
//  AVPlayer
//
//  Created by 刘全水 on 16/5/31.
//  Copyright © 2016年 刘全水. All rights reserved.
//

#import "LiuqsPlayControlView.h"

static const CGFloat ControlBarHeight = 40.0;
static const CGFloat kVideoControlAnimationTimeinterval = 0.25;
static const CGFloat kVideoControlBarAutoFadeOutTimeinterval = 3.0;

@implementation LiuqsPlayControlView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.isLectureSharkMode = YES;
        [self addSubview:self.PlaceHoderView];
        [self addSubview:self.bottomBar];
        [self addSubview:self.topBar];
        [self.bottomBar addSubview:self.playBtn];
        [self.bottomBar addSubview:self.pauseBtn];
        [self.bottomBar addSubview:self.fullScreenBtn];
        [self.bottomBar addSubview:self.shrinkScreenBtn];
        [self.bottomBar addSubview:self.cacheProgressView];
        [self.bottomBar addSubview:self.PlaySliderView];
        [self.bottomBar addSubview:self.rightTimeLabel];
        [self.bottomBar addSubview:self.sizeLabel];
        [self.topBar    addSubview:self.nameLabel];
        [self.topBar    addSubview:self.backBtn];
        [self addSubview:self.horizontalLabel];
        [self addSubview:self.waterMarkView];
//        [self addSubview:self.BottomProgressView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:tapGesture];
        [self addSubview:self.failView];
        self.isLoadingViewShow = NO;
    }
    return self;
}

- (void)layoutSubviews{

    [super layoutSubviews];
    self.bottomBar.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - ControlBarHeight - 5, CGRectGetWidth(self.bounds), ControlBarHeight + 5);
    self.topBar.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds), ControlBarHeight + 20);
    self.playBtn.frame = CGRectMake(CGRectGetMinX(self.bottomBar.bounds), CGRectGetHeight(self.bottomBar.bounds) - ControlBarHeight, ControlBarHeight, ControlBarHeight);
    self.pauseBtn.frame = self.playBtn.frame;
    self.fullScreenBtn.frame = CGRectMake(CGRectGetMaxX(self.bottomBar.bounds) - ControlBarHeight, CGRectGetHeight(self.bottomBar.bounds) - ControlBarHeight, ControlBarHeight, ControlBarHeight);
    self.shrinkScreenBtn.frame = self.fullScreenBtn.frame;
    self.PlaySliderView.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame), CGRectGetHeight(self.bottomBar.bounds)/2 - 10, CGRectGetMinX(self.fullScreenBtn.frame) - CGRectGetMaxX(self.playBtn.frame), 20);
    self.sizeLabel.frame = CGRectMake(CGRectGetMinX(self.PlaySliderView.frame) + 4, 27, 100, 15);
    self.rightTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.PlaySliderView.frame) - 80, 27, 80, 15);
    if (SCREEN_WIDTH == 414) {
     
        self.cacheProgressView.frame = CGRectMake(CGRectGetMinX(self.PlaySliderView.frame) + 2, CGRectGetHeight(self.bottomBar.bounds) / 2 - CGRectGetHeight(self.cacheProgressView.bounds) / 2, CGRectGetWidth(self.PlaySliderView.bounds) - 4, CGRectGetHeight(self.cacheProgressView.bounds));
    }else {
    
        self.cacheProgressView.frame = CGRectMake(CGRectGetMinX(self.PlaySliderView.frame) + 2, CGRectGetHeight(self.bottomBar.bounds) / 2 - CGRectGetHeight(self.cacheProgressView.bounds) / 2 + 0.5, CGRectGetWidth(self.PlaySliderView.bounds) - 4, CGRectGetHeight(self.cacheProgressView.bounds));
    }
    self.horizontalLabel.frame = CGRectMake(CGRectGetWidth(self.bounds) / 2 - 44, CGRectGetHeight(self.bounds) / 2 - 25, 88, 50);
    self.backBtn.frame = CGRectMake(15, 20, 44, 44);
    self.failView.frame = self.bounds;
    self.LoadingView.frame = self.bounds;
    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.backBtn.frame) + 5, 20, SCREEN_WIDTH - CGRectGetMaxX(self.backBtn.frame) - 5, 40);
    if (!self.isPlayerVCView) {
   
        self.waterMarkView.frame = CGRectMake(SCREEN_WIDTH - 55, (SCREEN_HEIGHT - SCREEN_WIDTH * 9 / 16) * 0.5 + 10, 40, 10);
    }else {
     self.waterMarkView.frame = CGRectMake(SCREEN_WIDTH - 55, 10, 40, 10);
    }
    self.BottomProgressView.frame = CGRectMake(0, self.Ex_height - 2.5, SCREEN_WIDTH, 5);
    self.PlaceHoderView.frame = CGRectMake(0, (self.Ex_height - SCREEN_WIDTH * 9 / 16) * 0.5, SCREEN_WIDTH, SCREEN_WIDTH * 9 / 16);
    
}



- (void)didMoveToSuperview {
    
    [super didMoveToSuperview];
    self.isBarShowing = YES;
    [self performSelector:@selector(animateHide) withObject:nil afterDelay:kVideoControlBarAutoFadeOutTimeinterval];
}

- (void)showLoadingView {
    
    if (!self.isLoadingViewShow) {
        
        [self insertSubview:self.LoadingView atIndex:0];
        self.isLoadingViewShow = YES;
    }
}

- (void)setIsBarShowing:(BOOL)isBarShowing {

    _isBarShowing = isBarShowing;
    if (isBarShowing) {
        
        self.BottomProgressView.hidden = YES;
    }else {
    
        self.BottomProgressView.hidden = NO;
    }
}

- (void)dissmissLoadingView {

    if (self.isLoadingViewShow) {
       [self.LoadingView removeFromSuperview];
        self.isLoadingViewShow = NO;
    }
}

#pragma mark - 懒加载控件

- (UIImageView *)PlaceHoderView {
    
    if (!_PlaceHoderView) {
        _PlaceHoderView = [[UIImageView alloc]init];
        _PlaceHoderView.hidden = YES;
        _PlaceHoderView.image = [UIImage imageNamed:@"playerPloceHoder.png"];
    }
    return _PlaceHoderView;
}

- (UIProgressView *)BottomProgressView {

    if (!_BottomProgressView) {
        
        _BottomProgressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
        _BottomProgressView.trackTintColor = [UIColor grayColor];
        _BottomProgressView.progress = 0.0f;
        _BottomProgressView.progressTintColor = NavigationBar_COLOR;
        _BottomProgressView.hidden = YES;
    }
    return _BottomProgressView;
}

- (UIImageView *)waterMarkView {

    if (!_waterMarkView) {
        
        _waterMarkView = [[UIImageView alloc]init];
        _waterMarkView.image = [UIImage imageNamed:@"Watermark"];
        _waterMarkView.contentMode = UIViewContentModeCenter;
    }
    return _waterMarkView;
}

- (LiuqsLoadingView *)LoadingView {

    if (!_LoadingView) {
        
        _LoadingView = [[LiuqsLoadingView alloc]init];
        _LoadingView.userInteractionEnabled = NO;
    }
    
    return _LoadingView;
}

- (LiuqsLoadFailView *)failView {

    if (!_failView) {
        _failView = [[LiuqsLoadFailView alloc]init];
        _failView.image = [UIImage imageNamed:LiuqsPlayerImageName(@"Load-failed_Background")];
        _failView.hidden = YES;
    }
    
    return _failView;
}

- (UIView *)topBar {
    
    if (!_topBar) {
        _topBar = [[UIImageView alloc]init];
        _topBar.image = [UIImage imageNamed:LiuqsPlayerImageName(@"bg_video_top")];
        _topBar.userInteractionEnabled = YES;
    }
    return _topBar;
}
- (UIView *)bottomBar{
    
    if (!_bottomBar) {
        _bottomBar = [[UIImageView alloc]init];
        _bottomBar.userInteractionEnabled = YES;
        _bottomBar.image = [UIImage imageNamed:LiuqsPlayerImageName(@"bg_video_bottom")];
    }
    return _bottomBar;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[UIButton alloc]init];
        _playBtn.hidden = YES;
        [_playBtn setImage:[UIImage imageNamed:LiuqsPlayerImageName(@"icon_Pause")] forState:UIControlStateNormal];
        
    }
    return _playBtn;
}

- (UIButton *)pauseBtn {

    if (!_pauseBtn) {
        _pauseBtn = [[UIButton alloc]init];
        [_pauseBtn setImage:[UIImage imageNamed:LiuqsPlayerImageName(@"icon_Play")] forState:UIControlStateNormal];
    }
    return _pauseBtn; 
}

- (UIButton *)fullScreenBtn {

    if (!_fullScreenBtn) {
        _fullScreenBtn = [[UIButton alloc]init];
        [_fullScreenBtn setImage:[UIImage imageNamed:LiuqsPlayerImageName(@"icon_group_video_fullscreen_nor")] forState:UIControlStateNormal];
    }
    return _fullScreenBtn;
}

- (UIButton *)shrinkScreenBtn {

    if (!_shrinkScreenBtn) {
        _shrinkScreenBtn = [[UIButton alloc]init];
        _shrinkScreenBtn.hidden = YES;
        [_shrinkScreenBtn setImage:[UIImage imageNamed:LiuqsPlayerImageName(@"shrinkscreen")] forState:UIControlStateNormal];
    }
    return _shrinkScreenBtn;
}

- (UISlider *)PlaySliderView
{
    if (!_PlaySliderView) {
        _PlaySliderView = [[UISlider alloc] init];
        _PlaySliderView.continuous = NO;
        [_PlaySliderView setThumbImage:[UIImage imageNamed:LiuqsPlayerImageName(@"icon_progress-Marker")] forState:UIControlStateNormal];
        [_PlaySliderView setMinimumTrackImage:[UIImage imageNamed:LiuqsPlayerImageName(@"progress-bar_--upper")] forState:UIControlStateNormal];
        [_PlaySliderView setMaximumTrackImage:[UIImage imageNamed:LiuqsPlayerImageName(@"slider")] forState:UIControlStateNormal];
        _PlaySliderView.value = 0.f;
        _PlaySliderView.continuous = YES;
    }
    return _PlaySliderView;
}

-(UIProgressView *)cacheProgressView
{
    if (!_cacheProgressView) {
        _cacheProgressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
        _cacheProgressView.trackTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        _cacheProgressView.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
    }
    return _cacheProgressView;
}

- (UILabel *)sizeLabel {
    
    if (!_sizeLabel) {
        
        _sizeLabel = [[UILabel alloc]init];
        _sizeLabel.textAlignment = NSTextAlignmentLeft;
        _sizeLabel.textColor = [UIColor whiteColor];
        _sizeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _sizeLabel;
}


- (UILabel *)rightTimeLabel {

    if (!_rightTimeLabel) {
       
        _rightTimeLabel = [[UILabel alloc]init];
        _rightTimeLabel.textColor = [UIColor whiteColor];
        _rightTimeLabel.textAlignment = NSTextAlignmentCenter;
        _rightTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        _rightTimeLabel.text = @"00:00/00:00";
    }
    return _rightTimeLabel;
}


- (UILabel *)horizontalLabel
{
    if (!_horizontalLabel) {
        _horizontalLabel = [[UILabel alloc] init];
        _horizontalLabel.textColor = [UIColor whiteColor];
        _horizontalLabel.layer.cornerRadius = 5;
        _horizontalLabel.layer.masksToBounds = YES;
        _horizontalLabel.textAlignment = NSTextAlignmentCenter;
        _horizontalLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        _horizontalLabel.hidden = YES;
        _horizontalLabel.backgroundColor = [UIColor colorWithRed:31.0 / 255.0 green:31.0 / 255.0 blue:31.0 / 255.0 alpha:0.9];
    }
    return _horizontalLabel;
}

- (UIButton *)backBtn {

    if (!_backBtn) {
        _backBtn = [[UIButton alloc]init];
        [_backBtn setImage:[UIImage imageNamed:@"nav_left_nor"] forState:UIControlStateNormal];
    }
    return _backBtn;
}

- (UILabel *)nameLabel {

    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.hidden = YES;
    }
    return _nameLabel;
}


#pragma mark - 隐藏或调出控制视图
- (void)onTap:(UITapGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBarShowing) {
            [self animateHide];
        } else {
            [self animateShow];
        }
    }
}

- (void)animateHide {
    
    if (!self.isBarShowing) {
        return;
    }
    if (self.animationHide) {
        self.animationHide();
    }
    [UIView animateWithDuration:kVideoControlAnimationTimeinterval animations:^{
        self.bottomBar.alpha = 0.0;
        self.topBar.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.isBarShowing = NO;
    }];
}

- (void)animateShow {
    
    if (self.isBarShowing) {
        return;
    }
    if (self.animationShow) {
        self.animationShow();
    }
    [UIView animateWithDuration:kVideoControlAnimationTimeinterval animations:^{
        self.bottomBar.alpha = 1.0;
        self.topBar.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.isBarShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

- (void)autoFadeOutControlBar {
    
    if (!self.isBarShowing) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
    [self performSelector:@selector(animateHide) withObject:nil afterDelay:kVideoControlBarAutoFadeOutTimeinterval];
}

- (UIImage *)createImageWithColor:(UIColor*)color {
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@end
