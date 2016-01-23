//
//  VoiceSearchViewController.m
//  HoundSDK Test Application
//
//  Created by Cyril Austin on 5/20/15.
//  Copyright (c) 2015 SoundHound, Inc. All rights reserved.
//

#import "VoiceSearchViewController.h"
#import <HoundSDK/HoundSDK.h>
#import "JSONAttributedFormatter.h"

#define VOICE_SEARCH_END_POINT       @"https://api.houndify.com/v1/audio"

#pragma mark - VoiceSearchViewController

@interface VoiceSearchViewController()<UISearchBarDelegate>

@property(nonatomic, strong) IBOutlet UIButton* listeningButton;
@property(nonatomic, strong) IBOutlet UIButton* searchButton;
@property(nonatomic, strong) IBOutlet UITextView* textView;

@property(nonatomic, strong) IBOutlet UISearchBar* searchBar;

@property(nonatomic, strong) UIView* levelView;

@end

@implementation VoiceSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup UI
    
    [self.searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch
        state:UIControlStateNormal];
    
    self.levelView = [[UIView alloc] init];
    
    self.levelView.backgroundColor = self.view.tintColor;
    
    CGFloat levelHeight = 2.0;
    
    self.levelView.frame = CGRectMake(
        0,
        self.view.frame.size.height - levelHeight,
        0,
        levelHeight
    );
    
    [self.view addSubview:self.levelView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add notifications
    
    [NSNotificationCenter.defaultCenter
        addObserver:self selector:@selector(updateState)
        name:HoundVoiceSearchStateChangeNotification object:nil];
    
    [NSNotificationCenter.defaultCenter
        addObserver:self selector:@selector(audioLevel:)
        name:HoundVoiceSearchAudioLevelNotification object:nil];
    
    [NSNotificationCenter.defaultCenter
        addObserver:self selector:@selector(hotPhrase)
        name:HoundVoiceSearchHotPhraseNotification object:nil];
    
    [self updateState];
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
    
    // Start voice search
    
    [HoundVoiceSearch.instance
        startSearchWithRequestInfo:requestInfo
        endPointURL:endPointURL
     
        responseHandler:^(NSError* error, HoundVoiceSearchResponseType responseType, id response, NSDictionary* dictionary) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
            
                if (error)
                {
                    // Handle error
                    
                    self.textView.text = error.localizedDescription;
                }
                else
                {
                    if (responseType == HoundVoiceSearchResponseTypePartialTranscription)
                    {
                        // Handle partial transcription
                        
                        HoundDataPartialTranscript* partialTranscript = (HoundDataPartialTranscript*)response;
                        
                        self.textView.text = partialTranscript.partialTranscript;
                    }
                    else if (responseType == HoundVoiceSearchResponseTypeHoundServer)
                    {
                        // Display response JSON
                        
                        self.textView.attributedText = [JSONAttributedFormatter
                            attributedStringFromObject:dictionary
                            style:nil];
                        
                        // Any properties from the documentation can be accessed through the keyed accessors, e.g.:
                        
                        HoundDataHoundServer* houndServer = response;
                        
                        HoundDataCommandResult* commandResult = houndServer.allResults.firstObject;
                
                        NSDictionary* nativeData = commandResult[@"NativeData"];
                        
                        NSLog(@"NativeData: %@", nativeData);
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
        
            self.listeningButton.selected = NO;
        
            self.searchBar.text = @"Not Ready";
            
            self.searchButton.userInteractionEnabled = NO;
            
            [self.searchButton setTitle:@"" forState:UIControlStateNormal];
            
            self.searchButton.hidden = YES;
            
            self.searchBar.showsCancelButton = NO;
            
            break;
        
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

- (void)audioLevel:(NSNotification*)notification
{
    // Display current audio level
    
    float audioLevel = [notification.object floatValue];
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear
        | UIViewAnimationOptionBeginFromCurrentState;
    
    [UIView animateWithDuration:0.05
        delay:0.0 options:options
     
        animations:^{

            self.levelView.frame = CGRectMake(
                0,
                self.view.frame.size.height - self.levelView.frame.size.height,
                audioLevel * self.view.frame.size.width,
                self.levelView.frame.size.height
            );
        }
     
        completion:^(BOOL finished) {
        }
    ];
}

- (void)hotPhrase
{
    // "OK Hound" detected
    
    [self startSearch];
}

- (IBAction)listeningButtonTapped
{
    self.listeningButton.enabled = NO;
    
    if (!self.listeningButton.selected)
    {
        // Start listening
        
        [HoundVoiceSearch.instance
        
            startListeningWithCompletionHandler:^(NSError* error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                
                    self.listeningButton.enabled = YES;
                    self.listeningButton.selected = YES;
                    
                    if (error)
                    {
                        self.textView.text = error.localizedDescription;
                    }
                });
            }
        ];
    }
    else
    {
        self.textView.text = nil;
        
        // Stop listening
        
        [HoundVoiceSearch.instance
        
            stopListeningWithCompletionHandler:^(NSError *error) {
            
                dispatch_async(dispatch_get_main_queue(), ^{
                
                    self.listeningButton.enabled = YES;
                    self.listeningButton.selected = NO;
                    
                    if (error)
                    {
                        self.textView.text = error.localizedDescription;
                    }
                });
            }
        ];
    }
}

- (IBAction)searchButtonTapped
{
    // Take action based on current voice search state
    
    switch (HoundVoiceSearch.instance.state)
    {
        case HoundVoiceSearchStateNone:
            
            break;
        
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

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    if (HoundVoiceSearch.instance.state == HoundVoiceSearchStateRecording)
    {
        [HoundVoiceSearch.instance cancelSearch];
    }
}

@end
