//
//  EKStreamView.h
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EKResusableCell <NSObject>

@property (nonatomic, retain) NSString *reuseIdentifier;

@end



@interface EKStreamViewCellInfo : NSObject 

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSUInteger index;

// You SHOULD ONLY access this property when this object is in visibleCellInfo!
@property (nonatomic, assign) UIView<EKResusableCell> *cell;

@end



@class EKStreamView;


@protocol EKStreamViewDelegate <UIScrollViewDelegate>

- (NSInteger)numberOfCellsInStreamView:(EKStreamView *)streamView;
- (NSInteger)numberOfColumnsInStreamView:(EKStreamView *)streamView;
- (UIView<EKResusableCell> *)cellForStreamView:(EKStreamView *)streamView atIndex:(NSInteger)index;
- (CGFloat)streamView:(EKStreamView *)streamView heightForCellAtIndex:(NSInteger)index;

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
    *rectsForCells;         // 2d EKWaterfallCellInfo
    
    NSMutableDictionary *cellCache; // reuseIdentifier => NSMutableArray
    NSSet *visibleCellInfo;
}

@property (nonatomic, assign) id<EKStreamViewDelegate> delegate;

- (id<EKResusableCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)reloadData;

@end
