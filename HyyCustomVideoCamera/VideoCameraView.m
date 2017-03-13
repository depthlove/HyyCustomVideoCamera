//
//  VideoCameraView.m
//  addproject
//
//  Created by 胡阳阳 on 17/3/3.
//  Copyright © 2017年 mac. All rights reserved.
//
#import "VideoCameraView.h"
#import "GPUImageBeautifyFilter.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PlayVideoViewController.h"
#import "UIView+Tools.h"
#define VIDEO_FOLDER @"videoFolder"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define TIMER_INTERVAL 0.05
typedef NS_ENUM(NSInteger, CameraManagerDevicePosition) {
    CameraManagerDevicePositionBack,
    CameraManagerDevicePositionFront,
};
@interface VideoCameraView ()
{
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    NSMutableArray* urlArray;
   float totalTime; //视频总长度 默认10秒
    float currentTime; //当前视频长度
    float lastTime; //记录上次时间
    UIView* progressPreView; //进度条
    float progressStep; //进度条每次变长的最小单位
}
@property (nonatomic ,strong) UIButton *camerafilterChangeButton;
@property (nonatomic ,strong) UIButton *cameraPositionChangeButton;
@property (nonatomic, assign) CameraManagerDevicePosition position;
@property (nonatomic, strong) UIButton *photoCaptureButton;
@property (nonatomic, strong) UIButton *cameraChangeButton;
@property (nonatomic, strong) UIButton *dleButton;
@property (nonatomic, strong) NSMutableArray *lastAry;

@property (nonatomic, assign) BOOL isRecoding;
@end

@implementation VideoCameraView

- (instancetype) initWithFrame:(CGRect)frame{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    if (totalTime==0) {
        totalTime =10;
        
    }
    lastTime = 0;
    progressStep = SCREEN_WIDTH*TIMER_INTERVAL/totalTime;
    preLayerWidth = SCREEN_WIDTH;
    preLayerHeight = SCREEN_HEIGHT;
    preLayerHWRate =preLayerHeight/preLayerWidth;
    _lastAry = [[NSMutableArray alloc] init];
    urlArray = [[NSMutableArray alloc]init];
    [self createVideoFolderIfNotExist];
    mainScreenFrame = frame;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    _position = CameraManagerDevicePositionBack;
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [videoCamera addAudioInputsAndOutputs];
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    filter = [[GPUImageSaturationFilter alloc] init];
    filteredVideoView = [[GPUImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [videoCamera addTarget:filter];
    [filter addTarget:filteredVideoView];
    [videoCamera startCameraCapture];
    [self addSomeView];
    UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    singleFingerOne.numberOfTouchesRequired = 1; //手指数
    singleFingerOne.numberOfTapsRequired = 1; //tap次数
    [filteredVideoView addGestureRecognizer:singleFingerOne];
    [self addSubview:filteredVideoView];
    
//    [videoCamera removeAllTargets];
//    filter = [[GPUImageBeautifyFilter alloc] init];
//    [videoCamera addTarget:beautifyFilter];
//    [beautifyFilter addTarget:filteredVideoView];
    
    return self;
}
- (void) addSomeView{
    
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 60.0, 100, 30.0)];
    timeLabel.font = [UIFont systemFontOfSize:15.0f];
    timeLabel.text = @"00:00:00";
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.textColor = [UIColor whiteColor];
    [filteredVideoView addSubview:timeLabel];
    
    
    UIView* btView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 45, SCREEN_HEIGHT - 125, 90, 90)];
    [btView makeCornerRadius:45 borderColor:nil borderWidth:0];
    btView.backgroundColor = UIColorFromRGB(0xeeeeee);
    [filteredVideoView addSubview:btView];
    
    _photoCaptureButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 40, SCREEN_HEIGHT- 120, 80, 80)];
    _photoCaptureButton.backgroundColor = UIColorFromRGB(0xfa5f66);

    [_photoCaptureButton addTarget:self action:@selector(startRecording:) forControlEvents:UIControlEventTouchUpInside];
    [_photoCaptureButton makeCornerRadius:40 borderColor:UIColorFromRGB(0x28292b) borderWidth:3];

    [filteredVideoView addSubview:_photoCaptureButton];
    

    
    
    _camerafilterChangeButton = [[UIButton alloc] init];
    _camerafilterChangeButton.frame = CGRectMake(SCREEN_WIDTH - 110,  25, 30.0, 30.0);
    UIImage* img = [UIImage imageNamed:@"beauty"];
    [_camerafilterChangeButton setImage:img forState:UIControlStateNormal];
    [_camerafilterChangeButton addTarget:self action:@selector(changebeautifyFilterBtn:) forControlEvents:UIControlEventTouchUpInside];
    [filteredVideoView addSubview:_camerafilterChangeButton];
    
    _cameraPositionChangeButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, 25, 30, 30)];
    UIImage* img2 = [UIImage imageNamed:@"cammera"];
    [_cameraPositionChangeButton setImage:img2 forState:UIControlStateNormal];
    [_cameraPositionChangeButton addTarget:self action:@selector(changeCameraPositionBtn:) forControlEvents:UIControlEventTouchUpInside];
    [filteredVideoView addSubview:_cameraPositionChangeButton];
    
    _cameraChangeButton  = [[UIButton alloc] init];
    _cameraChangeButton.hidden = YES;
    _cameraChangeButton.frame = CGRectMake(SCREEN_WIDTH - 100 , SCREEN_HEIGHT - 105.0, 52.6, 50.0);
    UIImage* img3 = [UIImage imageNamed:@"complete"];
    [_cameraChangeButton setImage:img3 forState:UIControlStateNormal];
    [_cameraChangeButton addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventTouchUpInside];
    [filteredVideoView addSubview:_cameraChangeButton];
    
    _dleButton = [[UIButton alloc] init];
    _dleButton.hidden = YES;
    _dleButton.frame = CGRectMake( 50 , SCREEN_HEIGHT - 105.0, 50, 50.0);
    UIImage* img4 = [UIImage imageNamed:@"del"];
    [_dleButton setImage:img4 forState:UIControlStateNormal];
    [_dleButton addTarget:self action:@selector(clickDleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [filteredVideoView addSubview:_dleButton];
    
    progressPreView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT -4 , 0, 4)];
    progressPreView.backgroundColor = UIColorFromRGB(0xffc738);
    [progressPreView makeCornerRadius:2 borderColor:nil borderWidth:0];
    [filteredVideoView addSubview:progressPreView];


}


- (IBAction)startRecording:(UIButton*)sender {
    
    if (!sender.selected) {
        lastTime = currentTime;
        [_lastAry addObject:[NSString stringWithFormat:@"%f",lastTime]];
        _camerafilterChangeButton.hidden = YES;
        _dleButton.hidden = YES;
        sender.selected = YES;
        pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Movie%lu.mov",urlArray.count]];
        unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
        
        movieWriter.encodingLiveVideo = YES;
        movieWriter.shouldPassthroughAudio = YES;
        [filter addTarget:movieWriter];
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
        _isRecoding = YES;
        _photoCaptureButton.backgroundColor = UIColorFromRGB(0xf8ad6a);
        fromdate = [NSDate date];
        myTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                   target:self
                                                 selector:@selector(updateTimer:)
                                                 userInfo:nil
                                                  repeats:YES];
        
    }else
    {
        
        _camerafilterChangeButton.hidden = NO;
        sender.selected = NO;
        videoCamera.audioEncodingTarget = nil;
        NSLog(@"Path %@",pathToMovie);
        if (pathToMovie == nil) {
            return;
        }
        _photoCaptureButton.backgroundColor = UIColorFromRGB(0xfa5f66);
//        UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, nil, nil, nil);
        [movieWriter finishRecording];
        [filter removeTarget:movieWriter];
        [myTimer invalidate];
        myTimer = nil;
        [urlArray addObject:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",pathToMovie]]];
        if (urlArray.count) {
            _dleButton.hidden = NO;
        }
    }
    
    
}

- (IBAction)stopRecording:(id)sender {
    videoCamera.audioEncodingTarget = nil;
    NSLog(@"Path %@",pathToMovie);
    if (pathToMovie == nil) {
        return;
    }
    UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, nil, nil, nil);
    if (_isRecoding) {
        [movieWriter finishRecording];
        [filter removeTarget:movieWriter];
        _isRecoding = NO;
    }
    
    timeLabel.text = @"00:00:00";
    [myTimer invalidate];
    myTimer = nil;
    
    if (_photoCaptureButton.selected) {
            [urlArray addObject:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",pathToMovie]]];
    }

//    [urlArray addObject:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",pathToMovie]]];
//    [self mergeAndExportVideosAtFileURLs:urlArray];
    NSString *path = [self getVideoMergeFilePathString];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self mergeAndExportVideos:urlArray withOutPath:path];
        [urlArray removeAllObjects];
        [_lastAry removeAllObjects];
        currentTime = 0;
        lastTime = 0;
        _dleButton.hidden = YES;
        [progressPreView setFrame:CGRectMake(0, SCREEN_HEIGHT - 4, 0, 4)];
        _photoCaptureButton.backgroundColor = UIColorFromRGB(0xfa5f66);
        _photoCaptureButton.selected = NO;
        _cameraChangeButton.hidden = YES;


    });
    
    

    
//    http://blog.csdn.net/ismilesky/article/details/51920113  视频与音乐合成
    //    http://www.jianshu.com/p/0f9789a6d99a 视频与音乐合成

    
    //[movieWriter cancelRecording];
}
-(void)clickDleBtn:(UIButton*)sender {
    float progressWidth = [_lastAry.lastObject floatValue]/10*SCREEN_WIDTH;
    [progressPreView setFrame:CGRectMake(0, SCREEN_HEIGHT - 4, progressWidth, 4)];
    currentTime = [_lastAry.lastObject floatValue];
    timeLabel.text = [NSString stringWithFormat:@"%.2f",currentTime];
    if (urlArray.count) {
        [urlArray removeLastObject];
        [_lastAry removeLastObject];
        if (urlArray.count == 0) {
            _dleButton.hidden = YES;
        }
        if (currentTime < 3) {
            _cameraChangeButton.hidden = YES;
        }
    }
    
}
- (void)mergeAndExportVideos:(NSArray*)videosPathArray withOutPath:(NSString*)outpath{
    if (videosPathArray.count == 0) {
        return;
    }
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime totalDuration = kCMTimeZero;
    for (int i = 0; i < videosPathArray.count; i++) {
//        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:videosPathArray[i]]];
        AVAsset *asset = [AVAsset assetWithURL:videosPathArray[i]];
        NSError *erroraudio = nil;
        //获取AVAsset中的音频 或者视频
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        //向通道内加入音频或者视频
        BOOL ba = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetAudioTrack
                                       atTime:totalDuration
                                        error:&erroraudio];
        
        NSLog(@"erroraudio:%@%d",erroraudio,ba);
        NSError *errorVideo = nil;
        AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetVideoTrack
                                       atTime:totalDuration
                                        error:&errorVideo];
        
        NSLog(@"errorVideo:%@%d",errorVideo,bl);
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
    }
    NSLog(@"%@",NSHomeDirectory());
    
    NSURL *mergeFileURL = [NSURL fileURLWithPath:outpath];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    //压缩
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:[AVAsset assetWithURL:videosPathArray[0]]
//                                                                      presetName:AVAssetExportPresetMediumQuality];
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"exporter%@",exporter.error);
        PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
        view.videoURL =mergeFileURL;
        //            [self.navigationController pushViewController:view animated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            
        [[self getCurrentVC] presentViewController:view animated:YES completion:nil];
        });
    }];
}
- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    NSError *error = nil;
    
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLArray) {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        [assetArray addObject:asset];
        
        NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
        if (tmpAry.count>0) {
            AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);

        }
    }
    if (assetTrackArray.count == 0) {
        return;
    }

    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        //音频通道
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:([dataSourceArray count]>0)?[dataSourceArray objectAtIndex:0]:nil
                             atTime:totalDuration
                              error:nil];
        //视频通道
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        NSLog(@"line371%lld , %d",asset.duration.value,asset.duration.timescale);
        // 视频架构层，用来规定video样式，比如合并两个视频，怎么放，是转90度还是边放边旋转
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MIN(assetTrack.naturalSize.height, assetTrack.naturalSize.width);

        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);

                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -0));
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);

        
         [layerInstruciton setTransform:CGAffineTransformIdentity atTime:kCMTimeZero];
        
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    NSString *path = [self getVideoMergeFilePathString];
    NSURL *mergeFileURL = [NSURL fileURLWithPath:path];
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 100);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW*preLayerHWRate);
    //    (CGSize) renderSize = (width = 720, height = 1280) 10s mov 11M  mp4 709kb
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UISaveVideoAtPathToSavedPhotosAlbum([[mergeFileURL absoluteString ] stringByReplacingOccurrencesOfString:@"file://" withString:@""], nil, nil, nil);
            PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
            view.videoURL =mergeFileURL;
            //            [self.navigationController pushViewController:view animated:YES];
            [[self getCurrentVC] presentViewController:view animated:YES completion:nil];
            
        });
    }];
    
}
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}
//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mov"];
    
    return fileName;
}

- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
}
-(void)changeCameraPositionBtn:(UIButton*)sender{
    
    switch (_position) {
        case CameraManagerDevicePositionBack: {
            if (videoCamera.cameraPosition == AVCaptureDevicePositionBack) {
                [videoCamera pauseCameraCapture];
                _position = CameraManagerDevicePositionFront;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [videoCamera rotateCamera];
                    [videoCamera resumeCameraCapture];
                });
            }
        }
            break;
        case CameraManagerDevicePositionFront: {
            if (videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
                [videoCamera pauseCameraCapture];
                _position = CameraManagerDevicePositionBack;
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [videoCamera rotateCamera];
                    [videoCamera resumeCameraCapture];
                });
            }
        }
            break;
        default:
            break;
    }
    
}
- (void)changebeautifyFilterBtn:(UIButton*)sender{
    if (!sender.selected) {

        sender.selected = YES;
        [videoCamera removeAllTargets];
        filter = [[GPUImageBeautifyFilter alloc] init];
        [videoCamera addTarget:filter];
        [filter addTarget:filteredVideoView];
        

    }else
    {
        sender.selected = NO;
        [videoCamera removeAllTargets];
        filter = [[GPUImageSaturationFilter alloc] init];
        [videoCamera addTarget:filter];
        [filter addTarget:filteredVideoView];
    }
}


- (void)updateTimer:(NSTimer *)sender{
//    NSDateFormatter *dateFormator = [[NSDateFormatter alloc] init];
//    dateFormator.dateFormat = @"HH:mm:ss";
//    NSDate *todate = [NSDate date];
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
//    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
//    NSDateComponents *comps  = [calendar components:unitFlags fromDate:fromdate toDate:todate options:NSCalendarWrapComponents];
//    //NSInteger hour = [comps hour];
//    //NSInteger min = [comps minute];
//    //NSInteger sec = [comps second];
//    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//    NSDate *timer = [gregorian dateFromComponents:comps];
//    NSString *date = [dateFormator stringFromDate:timer];
    
    
    currentTime += TIMER_INTERVAL;
    

    
    timeLabel.text = [NSString stringWithFormat:@"%.2f",currentTime];
    float progressWidth = progressPreView.frame.size.width+progressStep;
    [progressPreView setFrame:CGRectMake(0, SCREEN_HEIGHT - 4, progressWidth, 4)];
    if (currentTime>3) {
        _cameraChangeButton.hidden = NO;
    }
    
    //时间到了停止录制视频
    if (currentTime>=totalTime) {

        [self stopRecording:nil];
    }
}

- (void)setfocusImage{
    UIImage *focusImage = [UIImage imageNamed:@"96"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, focusImage.size.width, focusImage.size.height)];
    imageView.image = focusImage;
    CALayer *layer = imageView.layer;
    layer.hidden = YES;
    [filteredVideoView.layer addSublayer:layer];
    _focusLayer = layer;
    
}

- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        
        
        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.delegate = self;
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
        
        // 0.5秒钟延时
        [self performSelector:@selector(focusLayerNormal) withObject:self afterDelay:0.5f];
    }
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
}


- (void)focusLayerNormal {
    filteredVideoView.userInteractionEnabled = YES;
    _focusLayer.hidden = YES;
}


-(void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized && (_focusLayer == NO || _focusLayer.hidden)) {
        CGPoint location = [tgr locationInView:filteredVideoView];
        [self setfocusImage];
        [self layerAnimationWithPoint:location];
        AVCaptureDevice *device = videoCamera.inputCamera;
        CGPoint pointOfInterest = CGPointMake(0.5f, 0.5f);
        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [filteredVideoView frame].size;
        
        if ([videoCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
        }
        
        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        
        
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    
                    
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [device unlockForConfiguration];
                
                NSLog(@"FOCUS OK");
            } else {
                NSLog(@"ERROR = %@", error);
            }
        }
    }
}
@end
