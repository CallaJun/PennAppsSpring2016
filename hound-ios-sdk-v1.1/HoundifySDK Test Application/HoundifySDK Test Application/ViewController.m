//
//  ViewController.m
//  HoundifySDK Test Application
//
//  Created by Cyril Austin on 10/29/15.
//  Copyright © 2015 SoundHound, Inc. All rights reserved.
//

#import "ViewController.h"
#import <HoundSDK/HoundSDK.h>

#define VOICE_SEARCH_END_POINT       @"https://api.houndify.com/v1/audio"

#pragma mark - ViewController

@interface ViewController()

@property(nonatomic, strong) IBOutlet UILabel* statusLabel;
@property(nonatomic, strong) IBOutlet UITextView* responseTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup UI
    
    self.statusLabel.text = nil;
    self.responseTextView.text = nil;
    
    UIImage* image = [UIImage imageNamed:@"ic-hound-small"];
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
    
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    imageView.frame = CGRectMake(0, 0, 32, 32);
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithCustomView:imageView];
}

- (IBAction)search:(UIButton*)button
{
    self.statusLabel.text = nil;
    self.responseTextView.text = nil;
    
    NSURL* URL = [NSURL URLWithString:VOICE_SEARCH_END_POINT];
    
    NSDictionary* requestInfo = @{
    
        // Insert request parameters
    };
    
    // Show listening screen
    
    [Houndify.instance
        presentListeningViewControllerInViewController:self.navigationController
        fromView:button
        requestInfo:requestInfo
        endPointURL:URL
        responseHandler:^(NSError* error, HoundDataHoundServer* response, NSDictionary* dictionary) {
            
            if (error)
            {
                // Check for errors
                
                if ([error.domain isEqualToString:HoundVoiceSearchErrorDomain]
                    && error.code == HoundVoiceSearchErrorCodeCancelled)
                {
                    self.statusLabel.text = @"Search cancelled";
                }
                else if ([error.domain isEqualToString:HoundVoiceSearchErrorDomain]
                    && error.code == HoundVoiceSearchErrorCodeAuthenticationFailed)
                {
                    self.statusLabel.text = @"Authentication failed";
                }
                else
                {
                    self.statusLabel.text = @"Search failed";
                }
            }
            else
            {
                self.statusLabel.text = @"Response Received";
                
                // Display written response in UI
                
                HoundDataCommandResult* commandResult = response.allResults.firstObject;
                
                self.responseTextView.text = commandResult.writtenResponse;
                
                // Any properties from the documentation can be accessed through the keyed accessors, e.g.:
                
                NSDictionary* nativeData = commandResult[@"NativeData"];
                
                NSLog(@"NativeData: %@", nativeData);
            }
            
            [self dismissSearch];
        }
    ];
}

- (void)dismissSearch
{
    [Houndify.instance dismissListeningViewControllerAnimated:YES completionHandler:^{}];
}

@end
