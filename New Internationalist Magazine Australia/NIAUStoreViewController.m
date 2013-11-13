//
//  NIAUStoreViewController.m
//  New Internationalist Magazine Australia
//
//  Created by Simon Loffler on 8/10/13.
//  Copyright (c) 2013 New Internationalist Australia. All rights reserved.
//

#import "NIAUStoreViewController.h"

@interface NIAUStoreViewController ()
{
    NSArray *_products;
    NSNumberFormatter *_priceFormatter;
}
@end

@implementation NIAUStoreViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Load the products from iTunesConnect
    _products = nil;
    [[NIAUInAppPurchaseHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
            [self.tableView reloadData];
            [self.tableViewLoadingIndicator stopAnimating];
            
            // TODO: Get expiry date if you have a subscription.
            self.subscriptionExpiryDateLabel.text = @"TODO: date here.";
        }
    }];
    
    // Format the price of each product for different locales.
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    // Start Activity Indicator.
    self.subscriptionExpiryDateLabel.text = @"";
    [self.tableViewLoadingIndicator startAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)productPurchased:(NSNotification *)notification {
    
    NSString *productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct *product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            *stop = YES;
        }
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (_products) {
        return _products.count;
    } else {
        // TODO: set a default response for no products.
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"storeViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    if (_products) {
        SKProduct *product = _products[indexPath.row];
        UIImageView *productImageView = (UIImageView *)[cell viewWithTag:100];
        productImageView.image = nil;
        
        UILabel *productTitle = (UILabel *)[cell viewWithTag:101];
        productTitle.text = [product localizedTitle];
        
        UILabel *productPrice = (UILabel *)[cell viewWithTag:102];
        [_priceFormatter setLocale:product.priceLocale];
//        productPrice.text = [NSString stringWithFormat:@"$%0.2f",[product price].floatValue];
        productPrice.text = [_priceFormatter stringFromNumber:product.price];
        
        UILabel *productDescription = (UILabel *)[cell viewWithTag:103];
        productDescription.text = [product localizedDescription];
        
        UIButton *productBuyButton = (UIButton *)[cell viewWithTag:104];
        // TODO: change the label depending on whether the product has been purchased yet or not.
        
        if ([[NIAUInAppPurchaseHelper sharedInstance] productPurchased:product.productIdentifier]) {
            [productBuyButton removeFromSuperview];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryView = nil;
            cell.backgroundColor = [[self.navigationController.navigationBar tintColor] colorWithAlphaComponent:0.1];
        } else {
            productBuyButton.titleLabel.text = @"Buy";
            productBuyButton.tag = indexPath.row;
        }
    }
    
    return cell;
}

- (CGSize)calculateCellSize:(UITableViewCell *)cell inTableView:(UITableView *)tableView {
    
    CGSize fittingSize = CGSizeMake(tableView.bounds.size.width, 0);
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:fittingSize];
    
    return size;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return [self calculateCellSize:cell inTableView:tableView].height;
}

#pragma mark -
#pragma mark - Actions

- (IBAction)buyButtonTapped:(id)sender
{
    UIButton *buyButton = (UIButton *)sender;
    SKProduct *product = _products[buyButton.tag];
    
    NSLog(@"Starting purchase: %@...", product.productIdentifier);
    [[NIAUInAppPurchaseHelper sharedInstance] buyProduct:product];
}

- (IBAction)restorePurchasesButtonTapped:(id)sender
{
    [[NIAUInAppPurchaseHelper sharedInstance] restoreCompletedTransactions];
}

#pragma mark -
#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"TODO: Work out how to recalculate the cell height and then reload it.");
    
//    Not working!
    
//    for (int i = 0; i < self.tableView.indexPathsForVisibleRows.count; i++) {
//        [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
//    }
    [self.tableView reloadData];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end