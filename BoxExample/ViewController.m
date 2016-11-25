    //
    //  ViewController.m
    //  BoxExample
    //
    //  Created by Prsenjit Goswami on 25/11/16.
    //  Copyright © 2016 Prosenjit Goswami. All rights reserved.
    //

#import "ViewController.h"
#import <BoxContentSDK/BOXContentSDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        // Do any additional setup after loading the view, typically from a nib.

//    BOXContentClient *contentClient = [BOXContentClient defaultClient];
//    [contentClient authenticateWithCompletionBlock:^(BOXUser *user,
//                                                     NSError *error){
//            // BOXUser is returned if authentication was successful.
//            // Otherwise, error will contain the reason for failure (e.g. network
//            // connection)
//            // If the user canceled the authentication flow, error will be have
//            // domain:BOXContentSDKErrorDomain code:BOXContentSDKAPIUserCancelledError
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


@end
