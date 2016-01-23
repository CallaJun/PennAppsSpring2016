//
//  RawVoiceSearchViewController.m
//  HoundSDK Test Application
//
//  Created by Cyril Austin on 6/2/15.
//  Copyright (c) 2015 SoundHound, Inc. All rights reserved.
//

#import "RawVoiceSearchViewController.h"
#import <HoundSDK/HoundSDK.h>
#import "JSONAttributedFormatter.h"
#import "AudioTester.h"

#define VOICE_SEARCH_END_POINT       @"https://api.houndify.com/v1/audio"

#define SAMPLE_RATE                             44100

#pragma mark - RawVoiceSearchViewController

@interface RawVoiceSearchViewController()<UISearchBarDelegate>

@property(nonatomic, strong) IBOutlet UIButton* searchButton;
@property(nonatomic, strong) IBOutlet UITextView* textView;

@property(nonatomic, strong) IBOutlet UISearchBar* searchBar;

@end

@implementation RawVoiceSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch
        state:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add notification handler
    
    [NSNotificationCenter.defaultCenter
        addObserver:self selector:@selector(updateState)
        name:HoundVoiceSearchStateChangeNotification object:nil];
    
    [self updateState];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Stop the built-in audio system to use raw mode
    
    [HoundVoiceSearch.instance stopListeningWithCompletionHandler:nil];
    
    [HoundVoiceSearch.instance setupRawModeWithInputSampleRate:SAMPLE_RATE completionHandler:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)startSearch
{
    self.textView.text = nil;
    
    NSDictionary* requestInfo = @{
    
        // insert any additional parameters
    };

    NSURL* endPointURL = [NSURL URLWithString:VOICE_SEARCH_END_POINT];
    
    // Start audio unit test class
    
    [AudioTester.instance startAudioWithSampleRate:SAMPLE_RATE
    
        dataHandler:^(NSError* error, NSData* data) {
        
            if (data)
            {
                [HoundVoiceSearch.instance writeRawAudioData:data];
            }
            else if (error)
            {
                NSLog(@"Error: %@", error);
            }
        }
    ];
    
    // Start voice search
    
    [HoundVoiceSearch.instance
        startSearchWithRequestInfo:requestInfo
        endPointURL:endPointURL
     
        responseHandler:^(NSError* error, HoundVoiceSearchResponseType responseType, id response, NSDictionary* dictionary) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
            
                if (error)
                {
                    // Handle error
                    
                    [AudioTester.instance stopAudioWithHandler:nil];
                    
                    self.textView.text = error.localizedDescription;
                }
                else
                {
                    if (responseType == HoundVoiceSearchResponseTypePartialTranscription)
                    {
                        // Display partial transcription
                        
                        HoundDataPartialTranscript* partialTranscript = (HoundDataPartialTranscript*)response;
                        
                        self.textView.text = partialTranscript.partialTranscript;
                    }
                    else if (responseType == HoundVoiceSearchResponseTypeHoundServer)
                    {
                        // Display response JSON
                        
                        [AudioTester.instance stopAudioWithHandler:nil];
                        
                        self.textView.attributedText = [JSONAttributedFormatter
                            attributedStringFromObject:dictionary
                            style:nil];
                    }
                }
            });
        }
    ];
}

- (void)updateState
{
    [self removeClearButtonFromView:self.searchBar];
    
    // Update UI state based on voice search state
    
    switch (HoundVoiceSearch.instance.state)
    {
        case HoundVoiceSearchStateNone:
        case HoundVoiceSearchStateReady:
        
            self.searchBar.text = @"Ready";
            
            self.searchButton.userInteractionEnabled = YES;
            
            [self.searchButton setTitle:@"Search" forState:UIControlStateNormal];
            
            self.searchButton.backgroundColor = self.view.tintColor;
            self.searchButton.hidden = NO;
            
            self.searchBar.showsCancelButton = NO;
        
            break;
        
        case HoundVoiceSearchStateRecording:
        
            self.searchBar.text = @"Recording";
            
            self.searchButton.userInteractionEnabled = YES;
            
            [self.searchButton setTitle:@"Stop" forState:UIControlStateNormal];
            
            self.searchButton.backgroundColor = self.view.tintColor;
            self.searchButton.hidden = NO;
            
            self.searchBar.showsCancelButton = YES;
            
            [self enableButtonInView:self.searchBar];
        
            break;
        
        case HoundVoiceSearchStateSearching:
        
            self.searchBar.text = @"Searching";

            self.searchButton.userInteractionEnabled = YES;
            
            [self.searchButton setTitle:@"Stop" forState:UIControlStateNormal];
            
            self.searchButton.backgroundColor = self.view.tintColor;
            self.searchButton.hidden = NO;
            
            self.searchBar.showsCancelButton = NO;
            
            break;
        
        case HoundVoiceSearchStateSpeaking:
        
            self.searchBar.text = @"Speaking";

            self.searchButton.userInteractionEnabled = YES;
            
            [self.searchButton setTitle:@"Stop" forState:UIControlStateNormal];
            
            self.searchButton.backgroundColor = UIColor.redColor;
            self.searchButton.hidden = NO;
            
            self.searchBar.showsCancelButton = NO;
            
            break;
    }
}

- (IBAction)searchButtonTapped
{
    // Take action based on current voice search state
    
    switch (HoundVoiceSearch.instance.state)
    {
        case HoundVoiceSearchStateNone:
        case HoundVoiceSearchStateReady:
        
            [self startSearch];

            break;
        
        case HoundVoiceSearchStateRecording:
        
            [HoundVoiceSearch.instance stopSearch];
            
            break;
        
        case HoundVoiceSearchStateSearching:
        
            [HoundVoiceSearch.instance cancelSearch];
            
            break;
        
        case HoundVoiceSearchStateSpeaking:
        
            [HoundVoiceSearch.instance stopSpeaking];
            
            break;
    }
}

- (void)enableButtonInView:(UIView*)view
{
    for (UIButton* button in view.subviews)
    {
        if ([button isKindOfClass:UIButton.class])
        {
            button.enabled = YES;
        }
        
        [self enableButtonInView:button];
    }
}

- (void)removeClearButtonFromView:(UIView*)view
{
    for (UITextField* textField in view.subviews)
    {
        if ([textField isKindOfClass:UITextField.class])
        {
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            
            textField.textColor = UIColor.whiteColor;
        }
        
        [self removeClearButtonFromView:textField];
    }
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar*)searchBar
{
    return NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        self.textView.text = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    if (HoundVoiceSearch.instance.state == HoundVoiceSearchStateRecording)
    {
        [HoundVoiceSearch.instance cancelSearch];
    }
}

@end
