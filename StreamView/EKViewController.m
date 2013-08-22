//
//  EKViewController.m
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "EKViewController.h"
#import "MyCell.h"

static int MaxPage = 1;

@implementation EKViewController
@synthesize stream;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    randomHeights = [[NSMutableArray alloc] initWithCapacity:100];
    for (int i = 0; i < 100; i++) {
        CGFloat h = arc4random() % 200 + 50.f;
        [randomHeights addObject:@(h)];
    }
    stream.scrollsToTop = YES;
    
    stream.cellPadding = 5.0f;
    stream.columnPadding = 5.0f;
    
}

- (void)viewDidUnload
{
    [self setStream:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)numberOfCellsInStreamView:(EKStreamView *)streamView
{
    return [randomHeights count];
}

- (NSInteger)numberOfColumnsInStreamView:(EKStreamView *)streamView
{
    return 3;
}

- (UIView *)streamView:(EKStreamView *)streamView cellAtIndex:(NSInteger)index
{
    static NSString *CellID1 = @"MyCell1";
    static NSString *CellID2 = @"MyCell2";
    
    BOOL redCell = index % 3 == 0;
    NSString *CellID =  redCell ? CellID2 : CellID1;
    
    MyCell *cell;
    
    cell = (MyCell *)[streamView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[MyCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        cell.reuseIdentifier = CellID;
        if (redCell) cell.label.textColor = [UIColor redColor];
    }
    
    cell.label.text = [NSString stringWithFormat:@"%d",index];
    
    return cell;
}

- (CGFloat)streamView:(EKStreamView *)streamView heightForCellAtIndex:(NSInteger)index
{
    return [randomHeights[index] floatValue];
}

- (UIView *)headerForStreamView:(EKStreamView *)streamView
{
    MyCell *header = [[MyCell alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - stream.columnPadding * 2, 60)];
    header.label.text = @"This is the header";
    
    return header;
}

- (UIView *)footerForStreamView:(EKStreamView *)streamView
{
    if (page <= MaxPage) {
        MyCell *footer = [[MyCell alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - stream.columnPadding * 2, 60)];
        footer.label.text = @"This is the footer";
        
        return footer;
    } else {
        return nil;
    }
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    if (ABS(scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y) < 3
//        && page <= MaxPage) {
//        for (int i = 0; i < 100; i++) {
//            CGFloat h = arc4random() % 200 + 50.f;
//            [randomHeights addObject:[NSNumber numberWithFloat:h]];
//        }
//        
//        page++;
//        
//        [stream reloadData];
//    }
//}
//
@end
