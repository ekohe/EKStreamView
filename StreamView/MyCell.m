//
//  MyCell.m
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "MyCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation MyCell

@synthesize label, reuseIdentifier;



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect bgFrame = CGRectInset(self.bounds, 0.0f, 0.0f);
        UIView *bgView = [[UIView alloc] initWithFrame:bgFrame];
        bgView.layer.borderColor = [UIColor blackColor].CGColor;
        bgView.layer.borderWidth = 2.0f;
        [self addSubview:bgView];
        bgView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, bgFrame.size.width, 20)];
        label.center = CGPointMake(self.frame.size.width/ 2, self.frame.size.height/2);
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        [self addSubview:label];
    }
    
    return self;
}



@end
