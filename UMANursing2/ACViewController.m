//
//  ACViewController.m
//  UMANursing2
//
//  Created by Andrew J Cavanagh on 5/4/13.
//  Copyright (c) 2013 Andrew J Cavanagh. All rights reserved.
//

#import "ACViewController.h"
#import "ACCollectionViewCell.h"
#import "ACTapGestureRecognizer.h"
#import "ACPanoViewer.h"
#import "MBProgressHUD.h"

@interface ACViewController ()
{
    MBProgressHUD *hud;
}
@property (nonatomic, strong) NSArray *panoramaCells;
@property (nonatomic, strong) ACTapGestureRecognizer *tapSensor;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) NSString *currentPanoKey;
@property (nonatomic, strong) NSArray *cellStills;
@property (nonatomic, strong) NSOperationQueue *opQueue;
@end

@implementation ACViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"panoramas" ofType:@"plist"];
    self.panoramaCells = [NSArray arrayWithContentsOfFile:dataFile];
    
    self.tapSensor = [[ACTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.collectionView addGestureRecognizer:self.tapSensor];
    [self.tapSensor setDelegate:self];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.collectionView setAllowsMultipleSelection:NO];
    
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"DSC_0126.png"]]];
    self.opQueue = [[NSOperationQueue alloc] init];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeHUD];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.cellStills = nil;
}

- (void)loadStills
{
    NSMutableArray *theImages = [[NSMutableArray alloc] init];
    for (NSDictionary *data in self.panoramaCells)
    {
        NSString *imageName = [data valueForKey:@"image"];
        UIImage *theImage = [UIImage imageNamed:imageName];
        [theImages addObject:theImage];
    }
    self.cellStills = (NSArray *)theImages;
}

#pragma mark - CollectionView Delegate

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return self.panoramaCells.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    ACCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *categoryObject = [self.panoramaCells objectAtIndex:indexPath.item];
    
    [cell.cellNameLabel setText:[categoryObject valueForKey:@"name"]];
    
    if (!self.cellStills) [self loadStills];
    
    NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^(void){
        UIImage *image = [self.cellStills objectAtIndex:indexPath.item];
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell setBackgroundColor:[UIColor colorWithPatternImage:image]];
        });
    }];
    [self.opQueue addOperation:block];
    
    return cell;
}


#pragma ACTapGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint tapPoint = [sender locationInView:self.collectionView];
        NSIndexPath* tappedCellPath = [self.collectionView indexPathForItemAtPoint:tapPoint];
        
        if (![self.collectionView indexPathForItemAtPoint:tapPoint])
        {
            self.currentIndexPath = nil;
            return;
        }
        
        self.currentIndexPath = tappedCellPath;
        [self.collectionView selectItemAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
    }
    else if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.currentIndexPath)
        {
            [self performSelectorOnMainThread:@selector(indicateHUD) withObject:nil waitUntilDone:YES];
            
            [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(performCellTapWithIndex:) userInfo:self.currentIndexPath repeats:NO];
            
            //[self performSelectorInBackground:@selector(performCellTapWithIndex:) withObject:self.currentIndexPath];
            //[self performCellTapWithIndex:self.currentIndexPath];
        }
    }
    else if (sender.state == UIGestureRecognizerStateCancelled)
    {
        if (self.currentIndexPath)
        {
            [self.collectionView deselectItemAtIndexPath:self.currentIndexPath animated:YES];
        }
    }
}

- (void)performCellTapWithIndex:(NSTimer *)timer
{
    NSIndexPath *tappedCellPath = (NSIndexPath *)[timer userInfo];
    
    NSDictionary *categoryObject = [self.panoramaCells objectAtIndex:tappedCellPath.row];

    NSString *cubeMapName = [categoryObject valueForKey:@"cubefile"];
    self.currentPanoKey = cubeMapName;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"showPanorama" sender:self];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showPanorama"])
    {
        UINavigationController *n = (UINavigationController *)[segue destinationViewController];
        ACPanoViewer *v = (ACPanoViewer *)[[n viewControllers] objectAtIndex:0];
        v.panoKey = self.currentPanoKey;
    }
}

#pragma mark - HUD

- (void)indicateHUD
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        hud = [MBProgressHUD showHUDAddedTo:self.collectionView animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading Panorama...";
        hud.detailsLabelText = nil;
    });
}

- (void)removeHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hide:YES];
    });
}

@end
