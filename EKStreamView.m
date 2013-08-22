//
//  EKStreamView.m
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "EKStreamView.h"

@implementation EKStreamViewCellInfo

@synthesize frame, index, cell;

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[EKStreamViewCellInfo class]]) return NO;
    
    return index == [object index];
}

- (NSUInteger)hash
{
    return index;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: index: %d>",NSStringFromClass([self class]), index];
}

@end



@interface EKStreamView()

- (void)setup;
- (NSSet *)getVisibleCellInfo;
- (void)layoutCellWithCellInfo:(EKStreamViewCellInfo *)info;

@property (nonatomic) NSSet *visibleCellInfo;
@property (nonatomic) NSMutableDictionary *cellCache;

@end














@implementation EKStreamView

@synthesize delegate, visibleCellInfo, cellCache, cellPadding, columnPadding;
@synthesize headerView, footerView, contentView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    if (infoForCells.count) {
        NSInteger numberOfColumns = [delegate numberOfColumnsInStreamView:self];
        CGFloat destWidth = (self.bounds.size.width - (numberOfColumns + 1) * self.columnPadding) / numberOfColumns;
        if (ABS(destWidth - columnWidth) < 0.01f) {
            return;
        }
        
    }
    [self reloadData];
}


- (void)reloadData
{
    [cellHeightsByIndex removeAllObjects];
    [cellHeightsByColumn removeAllObjects];
    [rectsForCells removeAllObjects];
    [infoForCells removeAllObjects];
    [cellCache removeAllObjects];
    
    
    for (EKStreamViewCellInfo *cellInfo in visibleCellInfo) {
        [cellInfo.cell removeFromSuperview];
    }
    
    
    
    //We could not simply remove headerView/footerView from their parentView:we need to persist their state.
    //For example, if an UITextView is a subview of headerView/footerView, remove them from parentView will make the keyboard hide.
    if ([delegate respondsToSelector:@selector(headerForStreamView:)]) {
        UIView *tempHeaderView = [delegate headerForStreamView:self];
        if (tempHeaderView) {
            CGRect f = tempHeaderView.frame;
            f.origin = CGPointMake(0, cellPadding);
            f.size.width = self.bounds.size.width - columnPadding * 2;
            tempHeaderView.frame = f;
            
            if (headerView != tempHeaderView) {
                [headerView removeFromSuperview];
                headerView = tempHeaderView;
                [contentView addSubview:headerView];
            }
        }
        else {
            [headerView removeFromSuperview];
            headerView = nil;
        }
        
        
    } else {
        [headerView removeFromSuperview];
        headerView = nil;
    }
    
    if ([delegate respondsToSelector:@selector(footerForStreamView:)]) {
        UIView *tempFooterView = [delegate footerForStreamView:self];
        if (tempFooterView) {
            if (footerView != tempFooterView) {
                footerView = tempFooterView;
                [contentView addSubview:footerView];
            }
        }
        else {
            [footerView removeFromSuperview];
            footerView = nil;
        }
        
    } else {
        [footerView removeFromSuperview];
        footerView = nil;
    }

    
    // calculate height for all cells
    NSInteger numberOfColumns = [delegate numberOfColumnsInStreamView:self];
    columnWidth = (self.bounds.size.width - (numberOfColumns + 1) * self.columnPadding) / numberOfColumns;
    
    if (numberOfColumns < 1)
        [NSException raise:NSInvalidArgumentException format:@"The number of columns must be equal or greater than 1!"];
    
    NSInteger numberOfCells = [delegate numberOfCellsInStreamView:self];
    CGFloat *columnHeights = calloc(numberOfColumns, sizeof(CGFloat));
    CGFloat *cellX = calloc(numberOfColumns, sizeof(CGFloat));
    if (columnHeights == NULL || cellX == NULL) {
        [NSException raise:NSMallocException format:@"Allocating memory failed."];
    }
    
    
    CGFloat cellHeight = headerView ? headerView.bounds.size.height + cellPadding : cellPadding;
    for (int i = 0; i < numberOfColumns; i++) {
        [cellHeightsByColumn addObject:[NSMutableArray arrayWithCapacity:20]];
        [rectsForCells addObject:[NSMutableArray arrayWithCapacity:20]];
        cellX[i] = (i == 0 ? columnPadding : cellX[i - 1] + columnWidth + columnPadding);
        columnHeights[i] = cellHeight;
    }
    
    for (int i = 0; i < numberOfCells; i++) {
        CGFloat height = [delegate streamView:self heightForCellAtIndex:i];
        [cellHeightsByIndex addObject:@(height)];
        
        NSUInteger shortestCol = 0;
        for (int j = 1; j < numberOfColumns; j++) {
            
            if (columnHeights[j] < columnHeights[shortestCol] - 0.5f)
                shortestCol = j;
        }
        
        NSMutableArray *cellHeightsInCol = cellHeightsByColumn[shortestCol];
        [cellHeightsInCol addObject:@(height)];
        NSMutableArray *rectsForCellsInCol = rectsForCells[shortestCol];
        EKStreamViewCellInfo *info = [EKStreamViewCellInfo new];
        info.frame = CGRectMake(cellX[shortestCol], columnHeights[shortestCol] + cellPadding, columnWidth, height);
        info.index = i;
        [rectsForCellsInCol addObject:info];
        [infoForCells addObject:info];
        
        columnHeights[shortestCol] += height + cellPadding;
    }
    
    
    // determine the visible cells' range
    visibleCellInfo = [self getVisibleCellInfo];
    
    // draw the visible cells
    
    for (EKStreamViewCellInfo *info in visibleCellInfo) {
        [self layoutCellWithCellInfo:info];
    }
    
    CGFloat maxHeight = 0;
    for (int i = 0; i < numberOfColumns; i++) {
        if (columnHeights[i] > maxHeight)
            maxHeight = columnHeights[i];
    }
    
    maxHeight += cellPadding;
    
    if (footerView) {
        CGRect f = footerView.frame;
        f.origin = CGPointMake(columnPadding, maxHeight);
        f.size.width = self.bounds.size.width - columnPadding * 2;
        footerView.frame = f;
        maxHeight += footerView.bounds.size.height + cellPadding;
    }
    
    self.contentSize = CGSizeMake(0.0f, maxHeight);
    CGRect f = contentView.frame;
    f.size.height = maxHeight;
    f.size.width = self.bounds.size.width;
    contentView.frame = f;

    
    
    free(columnHeights);
    free(cellX);
}

- (id<EKResusableCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    NSMutableArray *cellArray = cellCache[identifier];
    id<EKResusableCell> cell = nil;
    if ([cellArray count] > 0) {
        cell = [cellArray lastObject];
        [cellArray removeLastObject];
    } 
    
    return cell;
}

- (CGFloat)columnWidth
{
    NSInteger numColumns = [delegate numberOfColumnsInStreamView:self];
    return (self.bounds.size.width - (numColumns + 1) * self.columnPadding) / numColumns;
}

#pragma mark - Private Methods

- (NSSet *)getVisibleCellInfo
{
    CGFloat offsetTop = self.contentOffset.y;
    CGFloat offsetBottom = offsetTop + self.bounds.size.height;
    NSMutableSet *ret = [NSMutableSet setWithCapacity:10];
    
    
    for (NSMutableArray *rectsForCellsInCol in rectsForCells) {
        for (int i = 0, c = [rectsForCellsInCol count]; i < c; i++) {
            EKStreamViewCellInfo *info = rectsForCellsInCol[i];
            CGFloat top = info.frame.origin.y;
            CGFloat bottom = CGRectGetMaxY(info.frame);
            
            if (bottom < offsetTop) { // The cell is above the current view rect
                continue; 
            } else if (top > offsetBottom) { // the cell is below the current view rect. stop searching this column
                break;
            } else {
                [ret addObject:info];
            }
            
        }
    }
    
    return ret;
}

- (void)layoutCellWithCellInfo:(EKStreamViewCellInfo *)info
{
    UIView<EKResusableCell> *cell = [delegate streamView:self cellAtIndex:info.index];
    cell.frame = info.frame;
    info.cell = cell;
    if ([delegate respondsToSelector:@selector(streamView:willDisplayCell:forIndex:)]) {
        [delegate streamView:self willDisplayCell:cell forIndex:info.index];
    }
    [contentView addSubview:cell];
}

- (void)setup
{
    delegateObj = [EKStreamViewUIScrollViewDelegate new];
    delegateObj.streamView = self;
    [super setDelegate:delegateObj];
    
    cellHeightsByIndex = [[NSMutableArray alloc] initWithCapacity:30];
    cellHeightsByColumn = [[NSMutableArray alloc] initWithCapacity:5];
    rectsForCells = [[NSMutableArray alloc] initWithCapacity:5];
    cellCache = [[NSMutableDictionary alloc] initWithCapacity:20];
    infoForCells = [[NSMutableArray alloc] initWithCapacity:30];
    
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
    contentView.autoresizesSubviews = NO;
    [self addSubview:contentView];
}

- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(EKStreamViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    if (scrollPosition == EKStreamViewScrollPositionNone) {
        return;
    }
    EKStreamViewCellInfo *cellInfo = infoForCells[index];
    CGFloat cellPositionY = cellInfo.frame.origin.y;
    CGFloat cellHeight = cellInfo.frame.size.height;
    CGFloat viewHeight = self.frame.size.height;
    CGFloat targetOffsetY = self.contentOffset.y;
    CGFloat minOffsetY = 0.0f;
    CGFloat maxOffsetY = self.contentSize.height - self.frame.size.height;
    switch (scrollPosition) {
        case EKStreamViewScrollPositionNone:
            break;
        case EKStreamViewScrollPositionTop:
            targetOffsetY = MIN(maxOffsetY, MAX(minOffsetY, cellPositionY));
            break;
        case EKStreamViewScrollPositionMiddle:
            targetOffsetY = MIN(maxOffsetY, MAX(minOffsetY, cellPositionY - (viewHeight - cellHeight) * 0.5));
            break;
        case EKStreamViewScrollPositionBottom:
            targetOffsetY = MIN(maxOffsetY, MAX(minOffsetY, cellPositionY - (viewHeight - cellHeight)));
            break;
    }
    [self setContentOffset:CGPointMake(0.0f, targetOffsetY) animated:animated];
}

@end





@implementation EKStreamViewUIScrollViewDelegate

@synthesize streamView;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSSet *newVisibleCellInfo = [streamView getVisibleCellInfo];
    NSSet *visibleCellInfo = streamView.visibleCellInfo;
    NSMutableDictionary *cellCache = streamView.cellCache;
    
    
    for (EKStreamViewCellInfo *info in visibleCellInfo) {
        if (![newVisibleCellInfo containsObject:info]) {
            // info.cell.retainCount: 1
            NSString *cellID = info.cell.reuseIdentifier;
            NSMutableArray *cellArray = cellCache[cellID];
            if (cellArray == nil) {
                cellArray = [NSMutableArray arrayWithCapacity:10];
                cellCache[cellID] = cellArray;
            }
            
            [cellArray addObject:info.cell];
            // info.cell.retainCount: 2
            [info.cell removeFromSuperview];
            // info.cell.retainCount: 1
        }
    }
    
    for (EKStreamViewCellInfo *info in newVisibleCellInfo) {
        if (![visibleCellInfo containsObject:info]) {
            [streamView layoutCellWithCellInfo:info];
        }
    }
    
    streamView.visibleCellInfo = newVisibleCellInfo;
    
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidScroll:)])
        [streamView.delegate scrollViewDidScroll:streamView];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidZoom:)])
        [streamView.delegate scrollViewDidZoom:streamView];
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
        [streamView.delegate scrollViewWillBeginDragging:streamView];
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
        [streamView.delegate scrollViewWillEndDragging:streamView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
        [streamView.delegate scrollViewDidEndDragging:streamView willDecelerate:decelerate];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)])
        [streamView.delegate scrollViewWillBeginDecelerating:streamView];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
        [streamView.delegate scrollViewDidEndDecelerating:streamView];
    
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
        [streamView.delegate scrollViewDidEndScrollingAnimation:streamView];
    
}



- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)])
        return [streamView.delegate viewForZoomingInScrollView:streamView];
    else
        return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)])
        [streamView.delegate scrollViewWillBeginZooming:scrollView withView:view];
    
}


- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
        [streamView.delegate scrollViewDidEndZooming:streamView withView:view atScale:scale];
    
}


- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)])
        return [streamView.delegate scrollViewShouldScrollToTop:streamView];
    else
        return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)])
        [streamView.delegate scrollViewDidScrollToTop:streamView];
    
}


@end

