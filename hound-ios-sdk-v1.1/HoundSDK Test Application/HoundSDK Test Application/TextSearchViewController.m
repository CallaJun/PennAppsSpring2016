//
//  TextSearchViewController.m
//  HoundSDK Test Application
//
//  Created by Cyril Austin on 5/20/15.
//  Copyright (c) 2015 SoundHound, Inc. All rights reserved.
//

#import "TextSearchViewController.h"
#import <HoundSDK/HoundSDK.h>
#import "JSONAttributedFormatter.h"

#define TEXT_SEARCH_END_POINT       @"https://api.houndify.com/v1/text"

#pragma mark - TextSearchViewController

@interface TextSearchViewController()<UISearchBarDelegate>

@property(nonatomic, strong) IBOutlet UISearchBar* searchBar;
@property(nonatomic, strong) IBOutlet UITextView* textView;

@end

@implementation TextSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self changeTextColor:self.searchBar];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)changeTextColor:(UIView*)view
{
    for (UITextField* textField in view.subviews)
    {
        if ([textField isKindOfClass:UITextField.class])
        {
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            
            textField.textColor = UIColor.whiteColor;
        }
        
        [self changeTextColor:textField];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    [searchBar resignFirstResponder];
    
    self.textView.text = nil;
    
    NSString* query = searchBar.text;
    
    if (query.length > 0)
    {
        NSDictionary* requestInfo = @{
        
            // insert any additional parameters
        };
        
        NSURL* endPointURL = [NSURL URLWithString:TEXT_SEARCH_END_POINT];
        
        // Start text search
        
        [HoundTextSearch.instance
            searchWithQuery:query
            requestInfo:requestInfo
            endPointURL:endPointURL
         
            completionHandler:^(NSError* error, NSString* query, HoundDataHoundServer* houndServer, NSDictionary* dictionary) {
             
                if (error)
                {
                    // Handle error
                    
                    self.textView.text = error.localizedDescription;
                }
                else if (houndServer)
                {
                    // Display response JSON
                    
                    self.textView.attributedText = [JSONAttributedFormatter
                        attributedStringFromObject:dictionary
                        style:nil];
                }
            }
        ];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        self.textView.text = nil;
    }
}

@end
