//
//  PlayVideoViewController.m
//  VideoRecord
//
//  Created by guimingsu on 15/4/27.
//  Copyright (c) 2015年 guimingsu. All rights reserved.
//

#import "PlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "UIView+Tools.h"
#import "MusicItemCollectionViewCell.h"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface MusicData : NSObject

@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* eid;
@property (nonatomic,strong) NSString* musicPath;
@property (nonatomic,strong) NSString* iconPath;

@end
@implementation MusicData

@end

@interface PlayVideoViewController ()<UITextFieldDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, strong) NSArray* musicAry;
@property (nonatomic,strong) UIVisualEffectView *visualEffectView;
@property (nonatomic,strong) UIView* musicBottomBar;
@property (nonatomic,strong) NSString* audioPath;

@property (nonatomic,strong) UIButton* musicBtn;

@end

@implementation PlayVideoViewController
{
    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    AVPlayerItem *playerItem;
    AVPlayerItem *audioPlayerItem;
    UIImageView* playImg;
}

@synthesize videoURL;


- (void)viewDidLoad {
    [super viewDidLoad];

    _musicAry = [NSArray arrayWithArray:[self creatMusicData]];

    _audioPlayer = [[AVPlayer alloc ]init];
    
    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
//    [self playMusic];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"预览";
    
    float videoWidth = self.view.frame.size.width;
    
    
    
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:playerLayer];
    
//    UITapGestureRecognizer *playTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause)];
//    [self.view addGestureRecognizer:playTap];
    
    [self pressPlayButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    playImg = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
    playImg.center = CGPointMake(videoWidth/2, videoWidth/2);
    [playImg setImage:[UIImage imageNamed:@"videoPlay"]];
    [playerLayer addSublayer:playImg.layer];
    playImg.hidden = YES;
    
    //create ui
    UIButton* completeBtn = [[UIButton alloc] init];
    [completeBtn setTitle:@"导出" forState:UIControlStateNormal];
    [completeBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
    completeBtn.alpha = .9;
    [completeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    completeBtn.backgroundColor = [UIColor whiteColor];
    [completeBtn addTarget:self action:@selector(exportVideo) forControlEvents:UIControlEventTouchUpInside];
    UIView* superView = self.view;
    [superView addSubview:completeBtn];
    [completeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(superView).offset(-20);
        make.width.height.equalTo(@(70));
    }];
    [completeBtn makeCornerRadius:35 borderColor:nil borderWidth:0];
    
    
    _musicBtn  = [[UIButton alloc] init];
    UIImage* musicImg = [UIImage imageNamed:@"music"];
    [_musicBtn setImage:musicImg forState:UIControlStateNormal];
    [_musicBtn addTarget:self action:@selector(showEditMusicBar:) forControlEvents:UIControlEventTouchUpInside];
    [superView addSubview:_musicBtn];
    [_musicBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView).offset(20);
        make.right.equalTo(superView).offset(-20);
        make.width.height.equalTo(@30);
    }];
    
    _musicBottomBar = [[UIView alloc] init];
    [self.view addSubview:_musicBottomBar];
    [_musicBottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(superView).offset(160);
        make.left.right.equalTo(superView);
        make.height.equalTo(@(160));
    }];
    
    
    
    
    UIBlurEffect *blurEffrct =[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    //毛玻璃视图
    _visualEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffrct];
//    _visualEffectView.alpha = 1;
    [_musicBottomBar addSubview:_visualEffectView];
    
    [_visualEffectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.left.top.bottom.equalTo(_musicBottomBar);
    }];
    
    UIButton* cancleBtn = [[UIButton alloc] init];
    [cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancleBtn.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [cancleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancleBtn.backgroundColor = [UIColor clearColor];
    [cancleBtn addTarget:self action:@selector(clickCancleBtn) forControlEvents:UIControlEventTouchUpInside];
    [_musicBottomBar addSubview:cancleBtn];
    [cancleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_musicBottomBar);
        make.height.equalTo(@(45));
        make.width.equalTo(@(83));
    }];
    
    UIButton* okBtn = [[UIButton alloc] init];
    [okBtn setTitle:@"确认" forState:UIControlStateNormal];
    [okBtn.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor clearColor];
    [okBtn addTarget:self action:@selector(clickOKBtn) forControlEvents:UIControlEventTouchUpInside];
    [_musicBottomBar addSubview:okBtn];
    [okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(_musicBottomBar);
        make.height.equalTo(@(45));
        make.width.equalTo(@(83));
    }];
    
    UIView* lineView = [[UIView alloc] init];
    lineView.backgroundColor = [UIColor grayColor];
    [_musicBottomBar addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(okBtn);
        make.left.right.equalTo(_musicBottomBar);
        make.height.equalTo(@(.5));
    }];

    

    
    //collectionView
    UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(83, 115);
    layout.estimatedItemSize = CGSizeMake(83, 115);

    //设置分区的头视图和尾视图是否始终固定在屏幕上边和下边
    layout.sectionFootersPinToVisibleBounds = YES;
    layout.sectionHeadersPinToVisibleBounds = YES;
    
    // 设置水平滚动方向
    //水平滚动
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    // 设置额外滚动区域
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // 设置cell间距
    //设置水平间距, 注意点:系统可能会跳转(计算不准确)
    layout.minimumInteritemSpacing = 0;
    //设置垂直间距
    layout.minimumLineSpacing = 0;
    
    
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, 115) collectionViewLayout:layout];
    
    //设置背景颜色
    collectionView.backgroundColor = [UIColor clearColor];
    
    
    // 设置数据源,展示数据
    collectionView.dataSource = self;
    //设置代理,监听
    collectionView.delegate = self;
    
    // 注册cell
    [collectionView registerClass:[MusicItemCollectionViewCell class] forCellWithReuseIdentifier:@"MyCollectionCell"];
    
    /* 设置UICollectionView的属性 */
    //设置滚动条
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    
    //设置是否需要弹簧效果
    collectionView.bounces = YES;

    [_musicBottomBar addSubview:collectionView];

    

    //保存到相册
    
}
-(void)exportVideo
{
    if (_audioPath) {
        [self mixAudioAndVido];
    }else
    {
        UISaveVideoAtPathToSavedPhotosAlbum([[videoURL absoluteString ] stringByReplacingOccurrencesOfString:@"file://" withString:@""], nil, nil, nil);
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}
-(void)clickOKBtn
{
    [self showEditMusicBar:_musicBtn];
}
-(void)clickCancleBtn
{
    [self showEditMusicBar:_musicBtn];
    _audioPath = nil;
    [_audioPlayer pause];
}
-(void)showEditMusicBar:(UIButton*)sendr
{
    if (!sendr.selected) {
        sendr.selected = YES;
        [_musicBottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view);
        }];
        // 更新约束
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }else
    {
        [_musicBottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(160);
        }];
        // 更新约束
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
        sendr.selected = NO;
    }
}

-(void)mixAudioAndVido
{
    //    audio529
    
    // 路径
    
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // 声音来源
    
//    NSURL *audioInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"audio529" ofType:@"mp3"]];
    
    NSURL *audioInputUrl = [NSURL fileURLWithPath:_audioPath];
    
    // 视频来源
    
    NSURL *videoInputUrl = videoURL;
    
    // 最终合成输出路径
    
    NSString *outPutFilePath = [documents stringByAppendingPathComponent:@"videoandoudio.mov"];
    
    // 添加合成路径
    

    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    NSString *fileName = [[documents stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mov"];
    
    
    
//    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:fileName];
    
    // 时间起点
    
    CMTime nextClistartTime = kCMTimeZero;
    
    // 创建可变的音视频组合
    
    AVMutableComposition *comosition = [AVMutableComposition composition];
    
    // 视频采集
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoInputUrl options:nil];
    
    // 视频时间范围
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    
    AVMutableCompositionTrack *videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 视频采集通道
    
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    //  把采集轨道数据加入到可变轨道之中
    
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:nextClistartTime error:nil];
    
    // 声音采集
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioInputUrl options:nil];
    
    // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
    
    CMTimeRange audioTimeRange = videoTimeRange;
    
    // 音频通道
    
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 音频采集通道
    
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    // 加入合成轨道之中
    
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:nextClistartTime error:nil];
    
    
    // 创建一个输出
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetHighestQuality];
    
    // 输出类型
    
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    
    // 输出地址
    
    assetExport.outputURL = outputFileUrl;
    
    // 优化
    
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    // 合成完毕
    
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        // 回到主线程
        
        dispatch_async(dispatch_get_main_queue(), ^{

            
             UISaveVideoAtPathToSavedPhotosAlbum([[outputFileUrl absoluteString ] stringByReplacingOccurrencesOfString:@"file://" withString:@""], nil, nil, nil);
            
            // 调用播放方法  outputFileUrl 这个就是合成视频跟音频的视频
            
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                [self dismissViewControllerAnimated:YES completion:nil];
            
        });
    }];

}
-(NSArray*)creatMusicData
{
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"music2" ofType:@"json"];
    NSData *configData = [NSData dataWithContentsOfFile:configPath];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingAllowFragments error:nil];
    NSArray *items = dic[@"music"];
    int i = 529 ;
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *item in items) {
        //        NSString *path = [baseDir stringByAppendingPathComponent:item[@"resourceUrl"]];
        MusicData *effect = [[MusicData alloc] init];
        effect.name = item[@"name"];
        effect.eid = item[@"id"];
        effect.musicPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"audio%d",i] ofType:@"mp3"];
        effect.iconPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"icon%d",i] ofType:@"png"];
        [array addObject:effect];
        i++;
    }

    return array;
}
-(void)playMusic
{
    // 路径
    

    
    
    NSURL *audioInputUrl = [NSURL fileURLWithPath:_audioPath];
    // 声音来源
    
//    NSURL *audioInputUrl = [NSURL URLWithString:_audioPath];
    
    

    audioPlayerItem =[AVPlayerItem playerItemWithURL:audioInputUrl];

    [_audioPlayer replaceCurrentItemWithPlayerItem:audioPlayerItem];
    
    [_audioPlayer play];
}

-(void)playOrPause{
    if (playImg.isHidden) {
        playImg.hidden = NO;
        [player pause];
        
    }else{
        playImg.hidden = YES;
        [player play];
    }
}

- (void)pressPlayButton
{
    [playerItem seekToTime:kCMTimeZero];
    [player play];
    if (_audioPath) {
        [audioPlayerItem seekToTime:kCMTimeZero];
        [_audioPlayer play];
    }
    
}

- (void)playingEnd:(NSNotification *)notification
{
    
    [self pressPlayButton];
//    if (playImg.isHidden) {
//        [self pressPlayButton];
//    }

//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// 告诉系统每组多少个
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _musicAry.count;
}

// 告诉系统每个Cell如何显示
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 1.从缓存池中取
    
    static NSString *cellID = @"MyCollectionCell";
    MusicItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    MusicData* data = [_musicAry objectAtIndex:indexPath.row];
    UIImage* image = [UIImage imageWithContentsOfFile:data.iconPath];
    cell.iconImgView.image = image;
    cell.nameLabel.text = data.name;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MusicData* data = [_musicAry objectAtIndex:indexPath.row];
    _audioPath = data.musicPath;
    [self playMusic];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    NSLog(@"PlayVideoViewController 释放了");
    
}

@end
