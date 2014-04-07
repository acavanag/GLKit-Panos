//
//  ACCollectionViewCell.m
//  UMANursing2
//
//  Created by Andrew J Cavanagh on 5/4/13.
//  Copyright (c) 2013 Andrew J Cavanagh. All rights reserved.
//

#import "ACCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation ACCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.9];
        [self.layer setShadowRadius:2.0f];
        [self.layer setShadowOffset:CGSizeMake(0, 1)];
        [self.layer setMasksToBounds:NO];
        
        CGPathRef path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 500, 500)].CGPath;
        [self.layer setShadowPath:path];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
        [self.contentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [self.contentView setAutoresizesSubviews:YES];

        CGFloat screenScale = [UIScreen mainScreen].scale;
        
        [self.layer setRasterizationScale:screenScale];
        [self.layer setShouldRasterize:YES];
        
        CAGradientLayer *shineLayer = [CAGradientLayer layer];
        shineLayer.frame = CGRectMake(0, 0, 500, 500);
        shineLayer.colors = [NSArray arrayWithObjects:
                             (id)[UIColor colorWithWhite:1.0f alpha:1.0f].CGColor,
                             (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:0.8f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:0.6f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:0.4f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:0.2f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:0.0f alpha:0.4f].CGColor,
                             nil];
        
        shineLayer.locations = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:0.0f],
                                [NSNumber numberWithFloat:0.03f],
                                [NSNumber numberWithFloat:0.2f],
                                [NSNumber numberWithFloat:0.4f],
                                [NSNumber numberWithFloat:0.6f],
                                [NSNumber numberWithFloat:0.8f],
                                [NSNumber numberWithFloat:1.0f],
                                nil];
        
        [shineLayer setOpaque:YES];
        [shineLayer setRasterizationScale:screenScale];
        [shineLayer setShouldRasterize:YES];
        [self.layer insertSublayer:shineLayer atIndex:0];
        
        self.cellNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 210, 420, 80)];
        self.cellNameLabel.textAlignment = NSTextAlignmentCenter;
        self.cellNameLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:34];
        self.cellNameLabel.backgroundColor = [UIColor clearColor];
        self.cellNameLabel.textColor = [UIColor whiteColor];
        self.cellNameLabel.numberOfLines = 0;
        self.cellNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.cellNameLabel.text = @"";
        self.cellNameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.cellNameLabel.layer.shadowOffset = CGSizeMake(0, -1);
        self.cellNameLabel.layer.shadowOpacity = 1.0;
        self.cellNameLabel.layer.shadowRadius = 1.0;
        [self.cellNameLabel.layer setRasterizationScale:[UIScreen mainScreen].scale];
        [self.cellNameLabel.layer setShouldRasterize:YES];
        [self.contentView addSubview:self.cellNameLabel];
        
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
        [self.selectedBackgroundView setBackgroundColor:[UIColor blackColor]];
        
    }
    return self;
}



@end
