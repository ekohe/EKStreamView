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


- (void)reloadData
{
    [cellHeightsByIndex removeAllObjects];
    [cellHeightsByColumn removeAllObjects];
    [rectsForCells removeAllObjects];
    [cellCache removeAllObjects];
    [headerView removeFromSuperview];
    [footerView removeFromSuperview];
    
    for (EKStreamViewCellInfo *cellInfo in visibleCellInfo) {
        [cellInfo.cell removeFromSuperview];
    }
    
    if ([delegate respondsToSelector:@selector(headerForStreamView:)]) {
        headerView = [delegate headerForStreamView:self];
        CGRect f = headerView.frame;
        f.origin = CGPointMake(columnPadding, cellPadding);
        headerView.frame = f;
        
        [self addSubview:headerView];
    } else {
        headerView = nil;
    }
    
    if ([delegate respondsToSelector:@selector(footerForStreamView:)]) {
        footerView = [delegate footerForStreamView:self];
        [self addSubview:footerView];
    } else {
        footerView = nil;
    }
    
    // calculate height for all cells
    NSInteger numberOfColumns = [delegate numberOfColumnsInStreamView:self];
    columnWidth = (self.frame.size.width - (numberOfColumns + 1) * self.columnPadding) / numberOfColumns;
    
    if (numberOfColumns < 1)
        [NSException raise:NSInvalidArgumentException format:@"The number of columns must be equal or greater than 1!"];
    
    NSInteger numberOfCells = [delegate numberOfCellsInStreamView:self];
    CGFloat *columnHeights = calloc(numberOfColumns, sizeof(CGFloat));
    CGFloat *cellX = calloc(numberOfCells, sizeof(CGFloat));
    if (columnHeights == NULL && cellX == NULL) {
        [NSException raise:NSMallocException format:@"Allocating memory failed."];
    }
    
    
    CGFloat cellHeight = headerView ? headerView.frame.size.height + cellPadding : cellPadding;
    for (int i = 0; i < numberOfColumns; i++) {
        [cellHeightsByColumn addObject:[NSMutableArray arrayWithCapacity:20]];
        [rectsForCells addObject:[NSMutableArray arrayWithCapacity:20]];
        cellX[i] = (i == 0 ? columnPadding : cellX[i - 1] + columnWidth + columnPadding);
        columnHeights[i] = cellHeight;
    }
    
    for (int i = 0; i < numberOfCells; i++) {
        CGFloat height = [delegate streamView:self heightForCellAtIndex:i];
        [cellHeightsByIndex addObject:[NSNumber numberWithFloat:height]];
        
        NSUInteger shortestCol = 0;
        for (int j = 1; j < numberOfColumns; j++) {
            
            if (columnHeights[j] < columnHeights[shortestCol])
                shortestCol = j;
        }
        
        NSMutableArray *cellHeightsInCol = [cellHeightsByColumn objectAtIndex:shortestCol];
        [cellHeightsInCol addObject:[NSNumber numberWithFloat:height]];
        NSMutableArray *rectsForCellsInCol = [rectsForCells objectAtIndex:shortestCol];
        EKStreamViewCellInfo *info = [EKStreamViewCellInfo new];
        info.frame = CGRectMake(cellX[shortestCol], columnHeights[shortestCol] + cellPadding, columnWidth, height);
        info.index = i;
        [rectsForCellsInCol addObject:info];
        
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
        footerView.frame = f;
        
        maxHeight += footerView.frame.size.height + cellPadding;
    }
    
    self.contentSize = CGSizeMake(0.0f, maxHeight);
    
    
    free(columnHeights);
    free(cellX);
}

- (id<EKResusableCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    NSMutableArray *cellArray = [cellCache objectForKey:identifier];
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
    return (self.frame.size.width - (numColumns + 1) * self.columnPadding) / numColumns;
}

#pragma mark - Private Methods

- (NSSet *)getVisibleCellInfo
{
    CGFloat offsetTop = self.contentOffset.y;
    CGFloat offsetBottom = offsetTop + self.frame.size.height;
    NSMutableSet *ret = [NSMutableSet setWithCapacity:10];
    
    
    for (NSMutableArray *rectsForCellsInCol in rectsForCells) {
        for (int i = 0, c = [rectsForCellsInCol count]; i < c; i++) {
            EKStreamViewCellInfo *info = [rectsForCellsInCol objectAtIndex:i];
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
    [self addSubview:cell];
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
            NSMutableArray *cellArray = [cellCache objectForKey:cellID];
            if (cellArray == nil) {
                cellArray = [NSMutableArray arrayWithCapacity:10];
                [cellCache setObject:cellArray forKey:cellID];
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

