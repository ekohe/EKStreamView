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
@property (nonatomic, unsafe_unretained) UIView<EKResusableCell> *cell;

@end



@class EKStreamView;


@protocol EKStreamViewDelegate <UIScrollViewDelegate>

- (NSInteger)numberOfCellsInStreamView:(EKStreamView *)streamView;
- (NSInteger)numberOfColumnsInStreamView:(EKStreamView *)streamView;
- (UIView<EKResusableCell> *)streamView:(EKStreamView *)streamView cellAtIndex:(NSInteger)index;
- (CGFloat)streamView:(EKStreamView *)streamView heightForCellAtIndex:(NSInteger)index;

@optional

- (UIView *)headerForStreamView:(EKStreamView *)streamView;
- (UIView *)footerForStreamView:(EKStreamView *)streamView;
- (void)streamView:(EKStreamView *)streamView willDisplayCell:(UIView<EKResusableCell> *)cell forIndex:(NSInteger)index;
@optional

@end


@interface EKStreamViewUIScrollViewDelegate : NSObject<UIScrollViewDelegate>
@property (nonatomic, unsafe_unretained) EKStreamView *streamView;

@end

typedef enum {
    EKStreamViewScrollPositionNone,
    EKStreamViewScrollPositionTop,
    EKStreamViewScrollPositionMiddle,
    EKStreamViewScrollPositionBottom
} EKStreamViewScrollPosition;

@interface EKStreamView : UIScrollView
{
    NSMutableArray
    *cellHeightsByIndex,    // 1d
    *cellHeightsByColumn,   // 2d
    *rectsForCells,         // 2d EKStreamViewCellInfo
    *infoForCells;          // 1d
    
    NSMutableDictionary *cellCache; // reuseIdentifier => NSMutableArray
    NSSet *visibleCellInfo;
    CGFloat columnWidth;
    EKStreamViewUIScrollViewDelegate *delegateObj;
}

@property (nonatomic, unsafe_unretained) id<EKStreamViewDelegate> delegate;
@property (nonatomic, assign) CGFloat columnPadding;
@property (nonatomic, assign) CGFloat cellPadding;

@property (nonatomic, readonly) CGFloat columnWidth;

@property (nonatomic, readonly) UIView *headerView, *footerView;
@property (nonatomic, readonly) UIView *contentView;

- (id<EKResusableCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)reloadData;
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(EKStreamViewScrollPosition)scrollPosition animated:(BOOL)animated;
@end
