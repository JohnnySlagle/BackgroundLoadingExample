//
//  JSRootViewController.m
//  BackgroundTableLoading
//
//  Created by Johnny on 11/15/12.
//  Copyright (c) 2012 Johnny Slagle. All rights reserved.
//

#import "JSRootViewController.h"

/*
 *  WhereAmI
 *
 *  This is a macro I developed to print out which function and the line it was called on.  Easy for debugging
 *
 *  E.g. -[ViewController viewDidUnload] [Line 67]
 */
#define WhereAmI NSLog((@"%s [Line %d] "), __PRETTY_FUNCTION__, __LINE__);


// Constant for number of background items to have
static NSInteger kNumberOfItems = 100;

@interface JSRootViewController ()

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation JSRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup UI Stuff
    self.title = @"Background Items";
    
    // NOTE: I setup two ways to addBackgroundItems.  With a button on the navbar and the newly added iOS 6 UIRefreshControl (pull down on the uitableview to see it work).
    
    // Setup Reload Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(startBackgroundLoadingWithQueues)];
    
    // Setup Reload Refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(startBackgroundLoadingWithQueues) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // NOTE: You would get faster response if you put this in the viewDidLoad.  I put it here so you can actually see the 'loading cell' for a bit.
    // Start background loading
    [self startBackgroundLoadingWithQueues];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)iTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)iTableView numberOfRowsInSection:(NSInteger)iSection {
    // If there are no items to display, show a loading screen
    if([self.dataSource count] == 0) {
        return 1;
    }
    // else, display the items
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)iTableView cellForRowAtIndexPath:(NSIndexPath *)iIndexPath {
    static NSString *aItemCellIdentifier = @"ItemCell";
    static NSString *aEmptyCellIdentifier = @"EmptyCell";
    
    UITableViewCell *aCell = nil;
    
    // Show a Loading Cell
    if([self.dataSource count] == 0) {
        aCell = [iTableView dequeueReusableCellWithIdentifier:aItemCellIdentifier];
        if (aCell == nil) {
            aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aEmptyCellIdentifier];
        }
        
        // Set Loading Text
        aCell.textLabel.text = @"Loading...";
        
        // Show the Loading Activity Indicator
        UIActivityIndicatorView *aLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [aLoadingIndicator startAnimating];
        aCell.accessoryView = aLoadingIndicator;
    } else {    // Item Cell
        aCell = [iTableView dequeueReusableCellWithIdentifier:aItemCellIdentifier];
        if (aCell == nil) {
            aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:aItemCellIdentifier];
        }
        
        // Pull in the data from the datasource
        aCell.textLabel.text = [NSString stringWithFormat:@"%@",[self.dataSource objectAtIndex:iIndexPath.row]];
        aCell.detailTextLabel.text = [NSString stringWithFormat:@"#%d",iIndexPath.row+1];
    }
    return aCell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)iTableView didSelectRowAtIndexPath:(NSIndexPath *)iIndexPath {
    [iTableView deselectRowAtIndexPath:iIndexPath animated:YES];
}

#pragma mark - Background Loading Option 1
- (void) startBackgroundLoadingWithQueues {
    // Log Progress
    WhereAmI;
    
    //NOTE: This method shows how to background load using custom queues
    //NOTE: The first step to start something in the background is to create a 'queue' that you are going to assign a 'block' to that you will dispatch_async. By dispatcaching asynchronously you are sending it to be executing in the background without 'blocking' the current thread you are on.  You can also dispatch_sync which would dispatch it on the current thread and block it.
    
    // Create a 'queue'
    dispatch_queue_t backgroundQueue = dispatch_queue_create("aBackgroundLoadingQueue", NULL);
    
    // Dispatch a block asynchronously on the above queue
    dispatch_async(backgroundQueue, ^{
        // Call the "Loading Method".
        
        // !!!NOTE: This could be where you would start the call to Parse.  However, just as note, Parse may already handle or execute everything on the background thread already.  You may need to check on that because it would be silly to do a background within a background.  Also, with Parse they would probably provide a completion method with their API so you would handle all the finishing up in that method rather than calling it like I am below.
        [self loadingMethod];
        
        // The method has finished so call a completion method
        [self finishedLoadingMethod];
    });
}

- (void)loadingMethod {
    // Log Progress
    WhereAmI;
    
    // NOTE: Temp 'loading method'.  You would replace this with whatever you would call to do the loading you needed done.
    for (int i = 0; i < kNumberOfItems; i++) {
        NSLog(@"Adding Object #%d",i);
        // Add a temp object
        [self.dataSource addObject:@"Background Loaded Item"];
        
        // simulate a delay by telling the thread to selep for a 1/100th of a second
        usleep(50000);
    }
}

- (void)finishedLoadingMethod {
    // Log Progress
    WhereAmI;    
    
    //NOTE: This could be where you woul do stuff that you would need done after the data has been loaded. E.g. Updating any UI elemtns

    
    // IMPORTANT NOTE: You need to remember that anything having to do with any sort of GUI or object that starts with UI needs to be done on the main thread.  For our example we want to reload the tableView's datasource.  To do this, we execute it on the 'main thread' as such:
    
    // NOTE: dispatch_get_main_queue() returns the main thread, it's nifty.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Do whatever UI stuff you need done.
        [self.tableView reloadData];
        
        // Stop the UIRefreshControl if it was used to start the loading. Remember it starts with  UI so it needs to be done in the main thread
        [self.refreshControl endRefreshing];
    });
}

#pragma mark - Background Loading Option 2 (For Demonstration Only)
- (void) startBackgroundLoadingWithSelectors {
    ////////
    // Note: I haven't implemented how you would use this method just showing you another option on how you could do this.
    // This method shows how to background load something
    // This way is a little easier BUT not as flexible or dynamic.  You just use a built in call to performSelector:OnBackgroundThread
    
    // Tell 'self' to perform a selector in the background
    // One of the problems with this is that you are then responsible to tell the UI that it has finished in the loadingMethod isntead of being able to do it in the queue like above
    [self performSelectorInBackground:@selector(loadingMethod) withObject:nil];
}


#pragma mark - Lazy Instantiation
- (NSMutableArray *) dataSource {
    if(_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
