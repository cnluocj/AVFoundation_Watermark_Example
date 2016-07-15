//
//  WatermarkTool.h
//  WatermarkExample
//
//  Created by 罗楚健 on 16/7/13.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol WatermarkToolDelegate <NSObject>
@optional
- (void)exportSuccess;
@end

@interface WatermarkTool : NSObject
@property (nonatomic) AVMutableComposition *composition;
@property (nonatomic) AVAsset *asset;

@property (nonatomic, assign) id<WatermarkToolDelegate> delegate;

- (BOOL)exportMovie;
@end
