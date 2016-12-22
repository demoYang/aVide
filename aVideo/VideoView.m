//
//  VideoView.m
//  Some
//
//  Created by mac on 15/12/22.
//  Copyright © 2015年 mac. All rights reserved.
//

#import "VideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPVolumeView.h>
//#import <m>

typedef enum  {
    ChangeNone,
    ChangeVoice,
    ChangeLigth,
    ChangeCMTime
}Change;


@interface VideoView ()

@property (nonatomic ,readwrite) AVPlayerItem *item;

@property (nonatomic ,readwrite) AVPlayerLayer *playerLayer;

@property (nonatomic ,readwrite) AVPlayer *player;

@property (nonatomic ,strong)  id timeObser;

@property (nonatomic ,assign) float videoLength;

@property (nonatomic ,assign) Change changeKind;

@property (nonatomic ,assign) CGPoint lastPoint;

@property (nonatomic, assign) BOOL shouldFlushSlider;

//Gesture
@property (nonatomic ,strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic ,strong) MPVolumeView *volumeView;
@property (nonatomic ,weak) UISlider *volumeSlider;
@property (nonatomic ,strong) UIView *darkView;
@end

@implementation VideoView

- (id)initWithUrl:(NSString *)path delegate:(id<VideoSomeDelegate>)delegate {
    if (self = [super init]) {
        _playerUrl = path;
        _someDelegate = delegate;
        [self setBackgroundColor:[UIColor blackColor]];
        [self setUpPlayer];
        [self addSwipeView];
    
    }
    return self;
}
- (void)setUpPlayer {
    NSURL *url = [NSURL URLWithString:_playerUrl];
    NSLog(@"%@",url);
    _item = [[AVPlayerItem alloc] initWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_item];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:_playerLayer];
    
    [self addVideoKVO];
    [self addVideoTimerObserver];
    [self addVideoNotic];
}
- (void)seekValue:(float)value {
    
    _shouldFlushSlider = NO;
    
    float toBeTime = value *_videoLength;
    
    [_player seekToTime:CMTimeMake(toBeTime, 1) completionHandler:^(BOOL finished) {
        
        NSLog(@"seek Over finished:%@",finished ? @"success ":@"fail");
        
        _shouldFlushSlider = finished;
        
    }];
    
}
- (void)stop {
    
    [self removeVideoTimerObserver];

    [self removeVideoNotic];

    [self removeVideoKVO];

    [_player pause];
    
    [_playerLayer removeFromSuperlayer];
    
    _playerLayer = nil;
    
    [_player replaceCurrentItemWithPlayerItem:nil];
    
    _player = nil;
    
    _item = nil;
}
#pragma mark - KVO
- (void)addVideoKVO
{
    //KVO
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removeVideoKVO {
    [_item removeObserver:self forKeyPath:@"status"];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
}
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {

    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = _item.status;
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                [_player play];
                _shouldFlushSlider = YES;
                _videoLength = floor(_item.asset.duration.value * 1.0/ _item.asset.duration.timescale);
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_item.error);
            }
                break;
                
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
    
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
    }
}
#pragma mark - Notic
- (void)addVideoNotic {
    
    //Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieJumped:) name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieStalle:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backGroundPauseMoive) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}
- (void)removeVideoNotic {
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)movieToEnd:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)movieJumped:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)movieStalle:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)backGroundPauseMoive {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

#pragma mark - TimerObserver
- (void)addVideoTimerObserver {
    __weak typeof (self)self_ = self;
    _timeObser = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        float currentTimeValue = time.value*1.0/time.timescale/self_.videoLength;
        NSString *currentString = [self_ getStringFromCMTime:time];

        if ([self_.someDelegate respondsToSelector:@selector(flushCurrentTime:sliderValue:)] && _shouldFlushSlider) {
            [self_.someDelegate flushCurrentTime:currentString sliderValue:currentTimeValue];
        } else {
            NSLog(@"no response");
        }
    }];
}
- (void)removeVideoTimerObserver {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [_player removeTimeObserver:_timeObser];
    _timeObser =  nil;
}


#pragma mark - Utils
- (NSString *)getStringFromCMTime:(CMTime)time
{
    float currentTimeValue = (CGFloat)time.value/time.timescale;//得到当前的播放时
    
    NSDate * currentDate = [NSDate dateWithTimeIntervalSince1970:currentTimeValue];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
    NSDateComponents *components = [calendar components:unitFlags fromDate:currentDate];
    
    if (currentTimeValue >= 3600 )
    {
        return [NSString stringWithFormat:@"%ld:%ld:%ld",components.hour,components.minute,components.second];
    }
    else
    {
        return [NSString stringWithFormat:@"%ld:%ld",components.minute,components.second];
    }
}

- (NSString *)getVideoLengthFromTimeLength:(float)timeLength
{
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeLength];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
    NSDateComponents *components = [calendar components:unitFlags fromDate:date];
    
    if (timeLength >= 3600 )
    {
        return [NSString stringWithFormat:@"%ld:%ld:%ld",components.hour,components.minute,components.second];
    }
    else
    {
        return [NSString stringWithFormat:@"%ld:%ld",components.minute,components.second];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _playerLayer.frame = self.bounds;
}

#pragma mark - release 
- (void)dealloc {
    NSLog(@"dealloc %@",NSStringFromSelector(_cmd));
    [self removeVideoTimerObserver];
    [self removeVideoNotic];
    [self removeVideoKVO];
}

@end

#pragma mark - VideoView (Guester)

@implementation VideoView (Guester)

- (void)addSwipeView {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    [self addGestureRecognizer:_panGesture];
    [self setUpDarkView];
}
- (void)setUpDarkView {
    _darkView = [[UIView alloc] init];
    [_darkView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_darkView setBackgroundColor:[UIColor blackColor]];
    _darkView.alpha = 0.0;
    [self addSubview:_darkView];
    
    NSMutableArray *darkArray = [NSMutableArray array];
    [darkArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_darkView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_darkView)]];
    [darkArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_darkView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_darkView)]];
    [self addConstraints:darkArray];
}

- (void)swipeAction:(UISwipeGestureRecognizer *)gesture {
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            _changeKind = ChangeNone;
            _lastPoint = [gesture locationInView:self];
        }
            break;
        case  UIGestureRecognizerStateChanged:
        {
            [self getChangeKindValue:[gesture locationInView:self]];
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (_changeKind == ChangeCMTime) {
                [self changeEndForCMTime:[gesture locationInView:self]];
            }
            _changeKind = ChangeNone;
            _lastPoint = CGPointZero;
        }
        default:
            break;
    }
    
}
- (void)getChangeKindValue:(CGPoint)pointNow {
    
    switch (_changeKind) {
            
        case ChangeNone:
        {
            [self changeForNone:pointNow];
        }
            break;
        case ChangeCMTime:
        {
            [self changeForCMTime:pointNow];
        }
            break;
        case ChangeLigth:
        {
            [self changeForLigth:pointNow];
        }
            break;
        case ChangeVoice:
        {
            [self changeForVoice:pointNow];
        }
            break;
            
        default:
            break;
    }
}
- (void)changeForNone:(CGPoint) pointNow {
    if (fabs(pointNow.x - _lastPoint.x) > fabs(pointNow.y - _lastPoint.y)) {
        _changeKind = ChangeCMTime;
    } else {
        float halfWight = self.bounds.size.width / 2;
        if (_lastPoint.x < halfWight) {
            _changeKind =  ChangeLigth;
        } else {
            _changeKind =   ChangeVoice;
        }
        _lastPoint = pointNow;
    }
}
- (void)changeForCMTime:(CGPoint) pointNow {
    float number = fabs(pointNow.x - _lastPoint.x);
    if (pointNow.x > _lastPoint.x && number > 10) {
        float currentTime = _player.currentTime.value / _player.currentTime.timescale;
        float tobeTime = currentTime + number*0.5;
        NSLog(@"forwart to  changeTo  time:%f",tobeTime);
    } else if (pointNow.x < _lastPoint.x && number > 10) {
        float currentTime = _player.currentTime.value / _player.currentTime.timescale;
        float tobeTime = currentTime - number*0.5;
        NSLog(@"back to  time:%f",tobeTime);
    }
}
- (void)changeForLigth:(CGPoint) pointNow {
    float number = fabs(pointNow.y - _lastPoint.y);
    if (pointNow.y > _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self minLigth];
        
    } else if (pointNow.y < _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self upperLigth];
    }
}
- (void)changeForVoice:(CGPoint)pointNow {
    float number = fabs(pointNow.y - _lastPoint.y);
    if (pointNow.y > _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self minVolume];
    } else if (pointNow.y < _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self upperVolume];
    }
}
- (void)changeEndForCMTime:(CGPoint)pointNow {
    if (pointNow.x > _lastPoint.x ) {
        NSLog(@"end for CMTime Upper");
        float length = fabs(pointNow.x - _lastPoint.x);
        [self upperCMTime:length];
    } else {
        NSLog(@"end for CMTime min");
        float length = fabs(pointNow.x - _lastPoint.x);
        [self mineCMTime:length];
    }
}
- (void)upperLigth {
    
    if (_darkView.alpha >= 0.1) {
        _darkView.alpha =  _darkView.alpha - 0.1;
    }
    
}
- (void)minLigth {
    if (_darkView.alpha <= 1.0) {
        _darkView.alpha =  _darkView.alpha + 0.1;
    }
}

- (void)upperVolume {
    if (self.volumeSlider.value <= 1.0) {
        self.volumeSlider.value =  self.volumeSlider.value + 0.1 ;
    }
    
}
- (void)minVolume {
    if (self.volumeSlider.value >= 0.0) {
        self.volumeSlider.value =  self.volumeSlider.value - 0.1 ;
    }
}
#pragma mark -CMTIME
- (void)upperCMTime:(float)length {

    float currentTime = _player.currentTime.value / _player.currentTime.timescale;
    float tobeTime = currentTime + length*0.5;
    if (tobeTime > _videoLength) {
        [_player seekToTime:_item.asset.duration];
    } else {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
    }
}
- (void)mineCMTime:(float)length {

    float currentTime = _player.currentTime.value / _player.currentTime.timescale;
    float tobeTime = currentTime - length*0.5;
    if (tobeTime <= 0) {
        [_player seekToTime:kCMTimeZero];
    } else {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
    }
}

- (MPVolumeView *)volumeView {
    
    if (_volumeView == nil) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.hidden = YES;
        [self addSubview:_volumeView];
    }
    return _volumeView;
}

- (UISlider *)volumeSlider {
    if (_volumeSlider== nil) {
        NSLog(@"%@",[self.volumeView subviews]);
        for (UIView  *subView in [self.volumeView subviews]) {
            if ([subView.class.description isEqualToString:@"MPVolumeSlider"]) {
                _volumeSlider = (UISlider*)subView;
                break;
            }
        }
    }
    return _volumeSlider;
}

@end

