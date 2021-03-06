//
//  LiuqsLoadingView.m
//  LiuqsVideoPlayerDemo
//
//  Created by 刘全水 on 16/9/18.
//  Copyright © 2016年 刘全水. All rights reserved.
//

#import "LiuqsLoadingView.h"
#import "LiuqsAnimations.h"


#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width

#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height

@interface LiuqsLoadingView ()

@property(nonatomic, strong)UIView  *animationView;

@property(nonatomic, strong)UIView  *animationView1;

@property(nonatomic, strong)UIView  *animationView2;


@end

@implementation LiuqsLoadingView

- (UILabel *)rateLabel {

    if (!_rateLabel) {
        _rateLabel = [[UILabel alloc]init];
        _rateLabel.font = [UIFont systemFontOfSize:15];
        _rateLabel.textColor = [UIColor whiteColor];
        _rateLabel.text = @"0B/秒";
        _rateLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _rateLabel;
}

- (UILabel *)loadLabel {

    if (!_loadLabel) {
        _loadLabel = [[UILabel alloc]init];
        _loadLabel.font = [UIFont systemFontOfSize:16];
        _loadLabel.textColor = [UIColor whiteColor];
        _loadLabel.text = @"加载中";
        _loadLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _loadLabel;
}

- (instancetype)init {

    if (self = [super init]) {
     
        [self loadView];
        [self addSubview:self.loadLabel];
        [self addSubview:self.rateLabel];
    }
    return self;
}

- (void)loadView {

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    NSArray *colors = @[colorOne,colorTwo,colorThree];
    [self createAnimationLayersWithColors:colors andRadius:5];
}


- (void)createAnimationLayersWithColors:(NSArray<UIColor*>*)colors andRadius:(CGFloat)radius {
    
    
    for (int i = 0; i < 3; i ++) {
        
        UIView *LoadView = [UIView new];
        LoadView.frame = CGRectMake(0, 0, radius * 2, radius * 2);
        LoadView.layer.opacity = 0;
        LoadView.layer.cornerRadius = radius;
        LoadView.layer.masksToBounds = YES;
        LoadView.backgroundColor = [colors objectAtIndex:i];
        [self addSubview:LoadView];
        if (i == 0) {
            self.animationView = LoadView;
        }else if (i == 1) {
            self.animationView1 = LoadView;
        }else if (i == 2) {
            self.animationView2 = LoadView;
        }
    }
}

- (void)didMoveToSuperview {

    [self startLoadingAnimation];
}

- (void)layoutSubviews {

    [super layoutSubviews];
    self.animationView.center  = CGPointMake((SCREEN_WIDTH - 60) * 0.5, (self.frame.size.height - 40) * 0.5);
    self.animationView1.center = CGPointMake((SCREEN_WIDTH - 60) * 0.5 + 1 * 30, (self.frame.size.height - 40) * 0.5);
    self.animationView2.center = CGPointMake((SCREEN_WIDTH - 60) * 0.5 + 2 * 30, (self.frame.size.height - 40) * 0.5);
    self.loadLabel.frame = CGRectMake(0, CGRectGetMaxY(self.animationView.frame) + 15, SCREEN_WIDTH, 20);
    self.rateLabel.frame = CGRectMake(0, CGRectGetMaxY(self.loadLabel.frame) + 5, SCREEN_WIDTH, 20);
}



- (void)startLoadingAnimation {
    
    [LiuqsAnimations addLoadingAnimationWithLayer:self.animationView.layer];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [LiuqsAnimations addLoadingAnimationWithLayer:self.animationView1.layer];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [LiuqsAnimations addLoadingAnimationWithLayer:self.animationView2.layer];
    });
    
}

@end
