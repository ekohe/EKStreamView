//
//  EKViewController.m
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "EKViewController.h"
#import "MyCell.h"

@interface CHDemoView : UIView
- (void)singleTapAction:(UITapGestureRecognizer*)ges;
@property (nonatomic,assign)CGRect originRect;
@end


@implementation CHDemoView
@synthesize originRect;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
        ges.numberOfTapsRequired = 1;
        ges.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:ges];
        
    }
    return self;
}

- (void)singleTapAction:(UITapGestureRecognizer *)ges {
    if (ges.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.5 animations:^{
            self.frame = self.originRect;
        } completion:^(BOOL isFinished){
            [self removeFromSuperview];
        }];
        
        
    }
}

@end

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
        [randomHeights addObject:[NSNumber numberWithFloat:h]];
    }
    stream.scrollsToTop = YES;
    
    stream.cellPadding = 5.0f;
    stream.columnPadding = 5.0f;
    
    [stream reloadData];
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
    return [[randomHeights objectAtIndex:index] floatValue];
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

- (void)didSelectCellInStreamView:(EKStreamView*)streamView celAtIndex:(NSInteger)index withInfo:(EKStreamViewCellInfo*)info {
    NSLog(@"didSelectCellInStreamView:%d",index);
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    CGRect imgFrame = [window convertRect:info.frame fromView:stream];
    
    CHDemoView *blackView = [[CHDemoView alloc] initWithFrame:imgFrame];
    blackView.backgroundColor = [UIColor blackColor];
    blackView.originRect = imgFrame;
    [window addSubview:blackView];
    
   
    [UIView animateWithDuration:0.5
                     animations:^{
                         blackView.frame = window.frame;
                     }
                     completion:^(BOOL finished){
                         
                     }];
    
    
}


- (void)didSelectCellHeaderInStreamView:(EKStreamView*)streamView {
    NSLog(@"didSelectCellHeaderInStreamView");
}

- (void)didSelectCellFooterInStreamView:(EKStreamView*)streamView {
    NSLog(@"didSelectCellHeaderInStreamView");
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    ScrollDirection scrollDirection;
    
    if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= scrollView.contentSize.height - self.view.frame.size.height) {
        if (self.lastContentOffsetY > scrollView.contentOffset.y) {
            scrollDirection = ScrollDirectionUp;
            //Show navigation bar
            if (self.navigationController.navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:NO animated:YES];
            }
            
        }
        else if (self.lastContentOffsetY < scrollView.contentOffset.y) {
            scrollDirection = ScrollDirectionDown;
            if (!self.navigationController.navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:YES animated:YES];
            }
            
        }
        
        self.lastContentOffsetY = scrollView.contentOffset.y;
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
