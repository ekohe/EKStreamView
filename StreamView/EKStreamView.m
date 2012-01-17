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
    return [NSString stringWithFormat:@"<EKWaterfallCellInfo: index: %d>", index];
}

@end



@interface EKStreamView()

- (void)setup;
- (NSSet *)getVisibleCellInfo;
- (UIView *)getCell;
- (void)layoutCellWithCellInfo:(EKStreamViewCellInfo *)info;

@property (nonatomic, retain) NSSet *visibleCellInfo;
@property (nonatomic, retain) NSMutableArray *cellPool;

@end














@implementation EKStreamView

@synthesize delegate, visibleCellInfo, cellPool;

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

- (void)dealloc
{
    [[super delegate] release];
    [cellHeightsByIndex release];
    [cellHeightsByColumn release];
    [heightsForColumns release];
    [rectsForCells release];
    [visibleCellInfo release];
    [cellPool release];
    [super dealloc];
}

- (void)reloadData
{
    [cellHeightsByIndex removeAllObjects];
    [cellHeightsByColumn removeAllObjects];
    [heightsForColumns removeAllObjects];
    [rectsForCells removeAllObjects];
    [cellPool removeAllObjects];
    
    // calculate height for all cells
    NSInteger numberOfColumns = [delegate numberOfColumnsInStreamView:self];
    if (numberOfColumns < 1)
        [NSException raise:NSInvalidArgumentException format:@"The number of columns must be equal or greater than 1!"];
    
    NSInteger numberOfCells = [delegate numberOfCellsInStreamView:self];
    CGFloat *columnHeights = calloc(numberOfColumns, sizeof(CGFloat));
    CGFloat *cellX = calloc(numberOfCells, sizeof(CGFloat));
    if (columnHeights == NULL && cellX == NULL) {
        [NSException raise:NSMallocException format:@"Allocating memory failed."];
    }
    
    
    CGFloat columnWidth = self.frame.size.width / numberOfColumns;
    for (int i = 0; i < numberOfColumns; i++) {
        [cellHeightsByColumn addObject:[NSMutableArray arrayWithCapacity:20]];
        [rectsForCells addObject:[NSMutableArray arrayWithCapacity:20]];
        [heightsForColumns addObject:[NSNumber numberWithFloat:0.0f]];
        cellX[i] = (i == 0 ? 0.0f : cellX[i - 1] + columnWidth);
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
        EKStreamViewCellInfo *info = [[EKStreamViewCellInfo new] autorelease];
        info.frame = CGRectMake(cellX[shortestCol], columnHeights[shortestCol], columnWidth, height);
        info.index = i;
        [rectsForCellsInCol addObject:info];
        
        columnHeights[shortestCol] += height;
    }
    
    
    // determine the visible cells' range
    [visibleCellInfo release];
    visibleCellInfo = [[self getVisibleCellInfo] retain];
    
    // draw the visible cells
    
    for (EKStreamViewCellInfo *info in visibleCellInfo) {
        [self layoutCellWithCellInfo:info];
    }
    
    CGFloat maxHeight = 0.0f;
    for (int i = 0; i < numberOfColumns; i++) {
        if (columnHeights[i] > maxHeight)
            maxHeight = columnHeights[i];
    }
    
    self.contentSize = CGSizeMake(0.0f, maxHeight);
    
    for (int i = 0; i < numberOfColumns; i++) {
        [heightsForColumns addObject:[NSNumber numberWithFloat:columnHeights[i]]];
    }
    
    free(columnHeights);
    free(cellX);
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

- (UIView *)getCell
{
    UIView *cell;
    if ([cellPool count] > 0) {
        cell = [[[cellPool lastObject] retain] autorelease];
        [cellPool removeLastObject];
    } else {
        cell = [delegate cellForStreamView:self];
    }
    
    return cell;
}

- (void)layoutCellWithCellInfo:(EKStreamViewCellInfo *)info
{
    UIView *cell = [self getCell];
    cell.frame = info.frame;
    [delegate streamView:self setContentForCell:cell atIndex:info.index];
    info.cell = cell;
    [self addSubview:cell];
}

- (void)setup
{
    EKStreamViewUIScrollViewDelegate *delegateObj = [EKStreamViewUIScrollViewDelegate new];
    delegateObj.streamView = self;
    [super setDelegate:delegateObj];
    
    cellHeightsByIndex = [[NSMutableArray alloc] initWithCapacity:30];
    cellHeightsByColumn = [[NSMutableArray alloc] initWithCapacity:5];
    heightsForColumns = [[NSMutableArray alloc] initWithCapacity:5];
    rectsForCells = [[NSMutableArray alloc] initWithCapacity:5];
    cellPool = [[NSMutableArray alloc] initWithCapacity:20];
}

@end





// TODO: in scrollView did scroll to position delegate method,
// 1. determine which cells should be visible
// 2. compare should-be-visible list to the current visibleCells list
//    For any missing cells, deque and setup it to the position;
//    for any cells that is there but not in should-be-visible list, remove it and put it into the queue.


@implementation EKStreamViewUIScrollViewDelegate

@synthesize streamView;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSSet *newVisibleCellInfo = [streamView getVisibleCellInfo];
    NSSet *visibleCellInfo = streamView.visibleCellInfo;
    NSMutableArray *cellPool = streamView.cellPool;
    for (EKStreamViewCellInfo *info in visibleCellInfo) {
        if (![newVisibleCellInfo containsObject:info]) {
            // info.cell.retainCount: 1
            [cellPool addObject:info.cell];
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
        return NO;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if ([streamView.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)])
        [streamView.delegate scrollViewDidScrollToTop:streamView];
    
}


@end

