//
//  VideoCameraView.h
//  addproject
//
//  Created by 胡阳阳 on 17/3/3.
//  Copyright © 2017年 mac. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "GPUImage.h"



@interface VideoCameraView : UIView
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSString *pathToMovie;
    GPUImageView *filteredVideoView;
    CALayer *_focusLayer;
    NSTimer *myTimer;
    UILabel *timeLabel;
    NSDate *fromdate;
    CGRect mainScreenFrame;
}
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER; 
@end

