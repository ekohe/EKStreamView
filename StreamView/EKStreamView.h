//
//  EKStreamView.h
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface EKStreamViewCellInfo : NSObject 

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSUInteger index;

// You SHOULD ONLY access this property when this object is in visibleCellInfo!
@property (nonatomic, assign) UIView *cell;

@end



@class EKStreamView;


@protocol EKStreamViewDelegate <UIScrollViewDelegate>

- (NSInteger)numberOfCellsInStreamView:(EKStreamView *)streamView;
- (NSInteger)numberOfColumnsInStreamView:(EKStreamView *)streamView;
- (UIView *)cellForStreamView:(EKStreamView *)streamView;
- (CGFloat)streamView:(EKStreamView *)streamView heightForCellAtIndex:(NSInteger)index;
- (void)streamView:(EKStreamView *)streamView setContentForCell:(UIView *)cell atIndex:(NSInteger)index;

@optional

@end


@interface EKStreamViewUIScrollViewDelegate : NSObject<UIScrollViewDelegate>
@property (nonatomic, assign) EKStreamView *streamView;

@end


@interface EKStreamView : UIScrollView
{
    NSMutableArray
    *cellHeightsByIndex,    // 1d
    *cellHeightsByColumn,   // 2d
    *heightsForColumns,     // 1d
    *rectsForCells,         // 2d EKWaterfallCellInfo
    *cellPool;              // 1d UIView
    
    NSSet *visibleCellInfo;
}

@property (nonatomic, assign) id<EKStreamViewDelegate> delegate;

- (void)reloadData;

@end
