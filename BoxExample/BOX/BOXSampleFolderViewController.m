    //
    //  FolderListingViewController.m
    //  BoxContentSDKSampleApp
    //
    //  Created on 1/6/15.
    //  Copyright (c) 2015 Box. All rights reserved.
    //

#import "BOXSampleFolderViewController.h"
#import "BOXSampleFileDetailsController.h"
#import "BOXSampleItemCell.h"
#import "BOXSampleLibraryAssetViewController.h"
#import "BOXSampleProgressView.h"
#import <Photos/Photos.h>

@interface BOXSampleFolderViewController () <UIAlertViewDelegate>

@property(nonatomic, readwrite, strong) NSArray *items;
@property(nonatomic, readwrite, strong) NSString *folderID;
@property(nonatomic, readwrite, strong) BOXFolder *folder;
@property(nonatomic, readwrite, strong) BOXContentClient *client;
@property(nonatomic, readwrite, strong) BOXRequest *request;

@end

@implementation BOXSampleFolderViewController

- (instancetype)initWithClient:(BOXContentClient *)client
                      folderID:(NSString *)folderID {
    if (self = [super init]) {
        _client = client;
        _folderID = folderID;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(retrieveItems)
                  forControlEvents:UIControlEventValueChanged];

    UIBarButtonItem *uploadButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Upload Here"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(uploadAction:)];
//    UIBarButtonItem *importButton =
//    [[UIBarButtonItem alloc] initWithTitle:@"Import"
//                                     style:UIBarButtonItemStylePlain
//                                    target:self
//                                    action:@selector(importAction:)];
//    self.navigationItem.rightBarButtonItems = @[ uploadButton, importButton ];
    self.navigationItem.rightBarButtonItems = @[ uploadButton ];

        // Get the current folder's informations
    BOXFolderRequest *folderRequest =
    [self.client folderInfoRequestWithID:self.folderID];
    [folderRequest
     performRequestWithCompletion:^(BOXFolder *folder, NSError *error) {
         self.folder = folder;
         self.navigationItem.title = [folder.name isEqualToString:@"All Files"] ? nil : folder.name;
     }];

    [self retrieveItems];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.request cancel];
    self.request = nil;
}

- (void)retrieveItems {
    [self.refreshControl beginRefreshing];

        // Retrieve all items from the folder.
    BOXFolderItemsRequest *itemsRequest =
    [self.client folderItemsRequestWithID:self.folderID];
    itemsRequest.requestAllItemFields = YES;
    [itemsRequest performRequestWithCompletion:^(NSArray *items, NSError *error) {
        if (error == nil) {

            NSPredicate *predicate =
            [NSPredicate predicateWithFormat:@"self.isFolder = %@", @(YES)];
            self.items = [items filteredArrayUsingPredicate:predicate];

            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
    }];

    self.request = itemsRequest;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *UserTableViewCellIdentifier = @"UserTableViewCellIdentifier";
    BOXSampleItemCell *cell =
    [tableView dequeueReusableCellWithIdentifier:UserTableViewCellIdentifier];

    if (cell == nil) {
        cell =
        [[BOXSampleItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                 reuseIdentifier:UserTableViewCellIdentifier];
        cell.client = self.client;
    }

    cell.item = self.items[indexPath.row];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOXItem *item = self.items[indexPath.row];
    UIViewController *controller = nil;

    if ([item isKindOfClass:[BOXFolder class]]) {
        controller = [[BOXSampleFolderViewController alloc]
                      initWithClient:self.client
                      folderID:((BOXFolder *)item).modelID];
    } else {
            //        controller = [[BOXSampleFileDetailsController alloc]
            //        initWithClient:self.client itemID:item.modelID
            //        itemType:item.type];
    }
    [self.navigationController pushViewController:controller animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOXItem *item = self.items[indexPath.row];
        NSString *message = [NSString
                             stringWithFormat:
                             @"This will delete \n%@\nAre you sure you wish to continue ?",
                             item.name];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Delete", nil];
        alertView.tag = indexPath.row;
        [alertView show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        BOXItem *item = self.items[alertView.tag];

        BOXErrorBlock errorBlock = ^void(NSError *error) {
            if (error) {
                UIAlertView *alertView =
                [[UIAlertView alloc] initWithTitle:nil
                                           message:@"Could not delete this item."
                                          delegate:nil
                                 cancelButtonTitle:nil
                                 otherButtonTitles:@"OK", nil];
                [alertView show];
            } else {
                NSMutableArray *array = [NSMutableArray arrayWithArray:self.items];
                [array removeObject:item];
                self.items = [array copy];
                [self.tableView reloadData];
            }
        };

        if ([item isKindOfClass:[BOXFolder class]]) {
            BOXFolderDeleteRequest *request =
            [self.client folderDeleteRequestWithID:item.modelID];
            [request performRequestWithCompletion:^(NSError *error) {
                errorBlock(error);
            }];
        } else if ([item isKindOfClass:[BOXFile class]]) {
            BOXFileDeleteRequest *request =
            [self.client fileDeleteRequestWithID:item.modelID];
            [request performRequestWithCompletion:^(NSError *error) {
                errorBlock(error);
            }];
        } else if ([item isKindOfClass:[BOXBookmark class]]) {
            BOXBookmarkDeleteRequest *request =
            [self.client bookmarkDeleteRequestWithID:item.modelID];
            [request performRequestWithCompletion:^(NSError *error) {
                errorBlock(error);
            }];
        }
    }
}

#pragma mark - Callbacks

- (void)uploadAction:(id)sender {
        // See the progress
    if (self.items.count > 0) {
        [self.tableView
         scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
         atScrollPosition:UITableViewScrollPositionTop
         animated:YES];
    }

    BOXSampleProgressView *progressHeaderView = [[BOXSampleProgressView alloc]
                                                 initWithFrame:CGRectMake(0.0f, 0.0f,
                                                                          CGRectGetWidth(self.tableView.bounds), 50.0f)];
    self.tableView.tableHeaderView = progressHeaderView;

    NSString *dummyImageName = @"Logo_Box_Blue_Whitebg_480x480.jpg";

        // check if the file is already in the current folder, if it is, we need to
        // upload a new version instead of performing a regular upload.
    NSInteger indexOfFile = NSNotFound;
    NSString *fileID = nil;
    for (BOXItem *item in self.items) {
        if ([item.name isEqualToString:dummyImageName]) {
            indexOfFile = [self.items indexOfObject:item];
            fileID = item.modelID;
            break;
        }
    }

    NSString *path =
    [[NSBundle mainBundle] pathForResource:dummyImageName ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];

        // Create our blocks
    BOXFileBlock completionBlock = ^void(BOXFile *file, NSError *error) {
        if (error == nil) {
            [self updateDataSourceWithNewFile:file atIndex:indexOfFile];
            [self.tableView reloadData];
        } else {
            UIAlertView *alertView =
            [[UIAlertView alloc] initWithTitle:nil
                                       message:@"Upload Failed"
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        self.tableView.tableHeaderView = nil;
    };
    BOXProgressBlock progressBlock = ^void(
                                           long long totalBytesTransferred, long long totalBytesExpectedToTransfer) {
        progressHeaderView.progressView.progress =
        (float)totalBytesTransferred / (float)totalBytesExpectedToTransfer;
    };

        // We did not find a file named similarly, we can upload normally the file.
    if (indexOfFile == NSNotFound) {
        BOXFileUploadRequest *uploadRequest =
        [self.client fileUploadRequestToFolderWithID:self.folderID
                                            fromData:data
                                            fileName:dummyImageName];
        uploadRequest.enableCheckForCorruptionInTransit = YES;
        [uploadRequest
         performRequestWithProgress:^(long long totalBytesTransferred,
                                      long long totalBytesExpectedToTransfer) {
             progressBlock(totalBytesTransferred, totalBytesExpectedToTransfer);
         }
         completion:^(BOXFile *file, NSError *error) {
             completionBlock(file, error);
         }];
    }
        // We already found the item. We will upload a new version of the file.
        // Alternatively, we can also rename the file and upload it like a regular new
        // file via a BOXFileUploadRequest
    else {
        BOXFileUploadNewVersionRequest *newVersionRequest =
        [self.client fileUploadNewVersionRequestWithID:fileID fromData:data];
        [newVersionRequest
         performRequestWithProgress:^(long long totalBytesTransferred,
                                      long long totalBytesExpectedToTransfer) {
             progressBlock(totalBytesTransferred, totalBytesExpectedToTransfer);
         }
         completion:^(BOXFile *file, NSError *error) {
             completionBlock(file, error);
         }];
    }
}

- (void)importAction:(id)sender {
        // This method allows us to import media from library using the Photos
        // framework. Once we get the fileURLs of selected assets,
        // we can invoke the upload request provided ContentSDK.
    __weak BOXSampleFolderViewController *weakSelf = self;

    UICollectionViewFlowLayout *layout =
    [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    BOXSampleLibraryAssetViewController *libraryAssetViewController =
    [[BOXSampleLibraryAssetViewController alloc]
     initWithCollectionViewLayout:layout];

    libraryAssetViewController.assetSelectionCompletionBlock = ^(
                                                                 NSArray *selectedPHAssets) {
        for (PHAsset *asset in selectedPHAssets) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            [[PHImageManager defaultManager]
             requestImageDataForAsset:asset
             options:options
             resultHandler:^(NSData *imageData, NSString *dataUTI,
                             UIImageOrientation orientation,
                             NSDictionary *info) {
                 NSURL *fileURL =
                 [info objectForKey:@"PHImageFileURLKey"];
                 NSString *filename = [fileURL.path lastPathComponent];
                 BOXFileUploadRequest *uploadRequest = [weakSelf.client
                                                        fileUploadRequestToFolderWithID:weakSelf.folderID
                                                        fromData:imageData
                                                        fileName:filename];
                 uploadRequest.enableCheckForCorruptionInTransit = YES;
                 [uploadRequest
                  performRequestWithProgress:nil
                  completion:^(BOXFile *file,
                               NSError *error) {

                      if (error == nil) {
                          [weakSelf
                           updateDataSourceWithNewFile:
                           file
                           atIndex:
                           NSNotFound];
                              //TODO:   [weakSelf.tableView reloadData];
                          UIAlertController *alert = [UIAlertController
                                                     alertControllerWithTitle: @"Successfully Uploaded" message:nil preferredStyle:UIAlertControllerStyleAlert];
                          [weakSelf
                           presentViewController:alert
                           animated:YES
                           completion:nil];
                          ;
                      } else if (
                                 error.code ==
                                 BOXContentSDKAPIErrorConflict) {
                          UIAlertController *alert = [UIAlertController
                                                      alertControllerWithTitle:
                                                      @"Name conflict"
                                                      message:
                                                      @"File "
                                                      @"with"
                                                      @" sam"
                                                      @"e "
                                                      @"name"
                                                      @" alr"
                                                      @"eady"
                                                      @" exi"
                                                      @"sts"
                                                      preferredStyle:
                                                      UIAlertControllerStyleAlert];
                          [alert
                           addAction:
                           [UIAlertAction
                            actionWithTitle:
                            @"Cancel"
                            style:
                            UIAlertActionStyleCancel
                            handler:
                            nil]];
                          [weakSelf
                           presentViewController:alert
                           animated:YES
                           completion:nil];
                      }
                  }];
             }];
        }
    };

    [self.navigationController pushViewController:libraryAssetViewController
                                         animated:YES];
}

#pragma mark - Private Helpers

- (void)updateDataSourceWithNewFile:(BOXFile *)file atIndex:(NSInteger)index {
    NSMutableArray *newItems = [NSMutableArray arrayWithArray:self.items];
    if (index == NSNotFound) {
        [newItems addObject:file];
    } else {
        [newItems replaceObjectAtIndex:index withObject:file];
    }
    self.items = newItems;
}

@end
