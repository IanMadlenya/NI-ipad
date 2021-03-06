//
//  NIAUMagazineArchiveViewController.m
//  New Internationalist Magazine Australia
//
//  Created by Simon Loffler on 25/06/13.
//  Copyright (c) 2013 New Internationalist Australia. All rights reserved.
//

#import "NIAUMagazineArchiveViewController.h"
#import "NIAUCell.h"
#import "NIAUCollectionReusableView.h"
#import "NIAUTableOfContentsViewController.h"
#import "NIAUPublisher.h"

NSString *kCellID = @"magazineCellID";              // UICollectionViewCell storyboard id
NSString *kHeaderCellID = @"sectionYearID";

@interface NIAUMagazineArchiveViewController ()

@end

@implementation NIAUMagazineArchiveViewController

- (void)dealloc {
    // to avoid potential crashes
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialize the array of issues
        self.issueYears = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // TODO: this second request is causing troubles
    if ([[NIAUPublisher getInstance] isReady]) {
        [self showIssues];
    } else {
        [self loadIssues];
    }
    
    self.title = @"Archive";
    [self sendGoogleAnalyticsStats];
}

- (void)sendGoogleAnalyticsStats
{
    // Setup Google Analytics
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:self.title];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createScreenView] build]];
    
    // Firebase send
    [FIRAnalytics logEventWithName:@"openScreen"
                        parameters:@{
                                     @"name": self.title,
                                     @"screenName": self.title
                                     }];
    DebugLog(@"Firebase pushed: %@", self.title);
}

// doublehandling from NIAUViewController...
-(void)loadIssues {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:PublisherDidUpdateNotification object:[NIAUPublisher getInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:PublisherFailedUpdateNotification object:[NIAUPublisher getInstance]];
    [[NIAUPublisher getInstance] requestIssues];
}

-(void)publisherReady:(NSNotification *)not {
    // Update the view
    [self showIssues];
}

-(void)showIssues {
    // Build issueYears array up
    for (int i = 0; i < [[NIAUPublisher getInstance] numberOfIssues]; i++) {
        NIAUIssue *issue = [[NIAUPublisher getInstance] issueAtIndex:i];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:issue.publication];
        NSString *thisIssueYear = [[NSNumber numberWithLong: components.year] stringValue];
        if ([self.issueYears count] > 0) {
            BOOL keyFound = FALSE;
            for (NSDictionary *year in self.issueYears) {
                for (id key in year) {
                    if (key == thisIssueYear) {
                        [[year objectForKey:key] addObject:[NSNumber numberWithInt:i]];
                        keyFound = TRUE;
                    }
                }
            }
            if (!keyFound) {
                NSMutableDictionary *thisYearDict = [[NSMutableDictionary alloc] init];
                NSMutableArray *issueIndex = [[NSMutableArray alloc] init];
                [issueIndex addObject:[NSNumber numberWithInt:i]];
                [thisYearDict setValue:issueIndex forKey:thisIssueYear];
                [self.issueYears addObject:thisYearDict];
            }
        } else {
            NSMutableDictionary *thisYearDict = [[NSMutableDictionary alloc] init];
            NSMutableArray *issueIndex = [[NSMutableArray alloc] init];
            [issueIndex addObject:[NSNumber numberWithInt:i]];
            [thisYearDict setValue:issueIndex forKey:thisIssueYear];
            [self.issueYears addObject:thisYearDict];
        }
    }
    [self.collectionView reloadData];
}

-(void)publisherFailed:(NSNotification *)not {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherDidUpdateNotification object:[NIAUPublisher getInstance]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PublisherFailedUpdateNotification object:[NIAUPublisher getInstance]];
    NSLog(@"Error - Publisher failed: %@",not);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:NSLocalizedString(@"publisher_error", nil)
                                                   delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
    [alert show];
    alert.delegate = nil;
    //[alert release];
    //[self.navigationItem setRightBarButtonItem:refreshButton];
}

#pragma mark -
#pragma mark CollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    NSInteger issuesInYear = 0;
    NSDictionary *year = self.issueYears[section];
    for (id key in year) {
        issuesInYear = [[year objectForKey:key] count];
    }
    return issuesInYear;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.issueYears count];
}

// AHA: UICollectionViewController implements UICollectionViewDataSource where this method is defined.
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // we're going to use a custom UICollectionViewCell, which will hold an image and its label
    NIAUCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NIAUCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:
                                         UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderCellID forIndexPath:indexPath];
    NSString *year = @"";
    for (id key in self.issueYears[indexPath.section]) {
        year = key;
    }
    headerView.year.text = year;

    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(NIAUCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // iOS 13 calls willDisplayCell, so update image here now
    
    CGSize size = CGSizeMake(0,0);
    size = [self calculateCellSizeForScreenSize:self.view.frame.size];
    cell.image.image = nil;
    // Start background loading of the magazine cover
    [self loadImageForCell:cell withSize:size atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self calculateCellSizeForScreenSize:self.view.frame.size];
}

- (CGSize)calculateCellSizeForScreenSize:(CGSize)size
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL landscape = (UIDeviceOrientationLandscapeLeft == orientation) || (UIDeviceOrientationLandscapeRight == orientation);
    int columns = 0;
    
    if (landscape) {
        columns = 5;
    } else {
        if (IS_IPAD()) {
            columns = 4;
        } else {
            columns = 3;
        }
    }
    
    CGSize returnSize = CGSizeMake((size.width/columns)-10, (size.width*1415/(1000*columns))-10);
//    DebugLog(@"Calculated size: %f, %f", returnSize.width, returnSize.height);
    return returnSize;
}

- (void)loadImageForCell: (NIAUCell *)cell withSize: (CGSize)size atIndexPath:(NSIndexPath *)indexPath
{
    cell.image.image = [UIImage imageNamed:@"ni-logo-grey.png"];
    [cell.coverLoadingIndicator startAnimating];

    NSNumber *issueIndex = 0;
    NSDictionary *year = self.issueYears[indexPath.section];
    for (id key in year) {
        issueIndex = [year objectForKey:key][indexPath.row];
    }

    [[[NIAUPublisher getInstance] issueAtIndex:[issueIndex intValue]] getCoverThumbWithSize:size andCompletionBlock:^(UIImage *img) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Is cell is still in view
            NIAUCell *updateCell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];

            if (img && [[self.collectionView visibleCells] containsObject:updateCell]) {
                if (updateCell) {
                    [updateCell.coverLoadingIndicator stopAnimating];
                    [updateCell.image setAlpha:0.0];
                    [updateCell.image layoutIfNeeded];
                    [updateCell.image setImage:[NIAUHelper imageWithRoundedCornersSize:3. usingImage:img]];
                    [UIView animateWithDuration:0.3 animations:^{
                        [updateCell.image setAlpha:1.0];
                    }];
                }
            }
        });
    }];
}

// the user tapped a collection item, load and set the image on the detail view controller

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTableOfContents"])
    {
        NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0];
        
        NSNumber *issueIndex = 0;
        NSDictionary *year = self.issueYears[selectedIndexPath.section];
        for (id key in year) {
            issueIndex = [year objectForKey:key][selectedIndexPath.row];
        }
        
        NIAUTableOfContentsViewController *tableOfContentsViewController = [segue destinationViewController];
        tableOfContentsViewController.issue = [[NIAUPublisher getInstance] issueAtIndex:[issueIndex intValue]];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - Rotation handling

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Code to prepare for transition
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Handle change
        [self.collectionView performBatchUpdates:nil completion:nil];
        
        // TODO: get this working for the rotation crash bug that occurs when new issues are downloaded
        // Tried this, doesn't work
        //    [self.collectionView performBatchUpdates:^{
        //        [self.collectionView reloadData];
        //    } completion:^(BOOL finished) {
        //
        //    }];
    }];
}

@end
