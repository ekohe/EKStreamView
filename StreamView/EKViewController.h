//
//  EKViewController.h
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EKStreamView.h"

@interface EKViewController : UIViewController<EKStreamViewDelegate>
{
    NSMutableArray *randomHeights;
}
@property (retain, nonatomic) IBOutlet EKStreamView *stream;

@end
