//
//  ADVWebViewController.m
//  ADVcertificator-sample
//
//  Created by Daniel Cerutti on 12/13/12.
//  Copyright (c) 2012 ADVTOOLS. All rights reserved.
//
//  This file is part of ADVcertificator.
//
//  ADVcertificator is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ADVcertificator is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ADVcertificator.  If not, see <http://www.gnu.org/licenses/>.

#import "ADVWebViewController.h"
#import "ADVCertificateViewController.h"
#import "ADVCertificator/ADVCertificator.h"
#import "ADVCertificator/ADVX509Certificate.h"

@interface ADVWebViewController () <UITextFieldDelegate, UIWebViewDelegate, ADVCertificatorDelegate, UIAlertViewDelegate>
{
    dispatch_semaphore_t semaphore;
}

@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSData *serverCertificateData;

@property (weak, nonatomic) IBOutlet UILabel *serverCertificateLabel;
@property (weak, nonatomic) IBOutlet UIButton *serverCertificateButton;

@end

@implementation ADVWebViewController

@synthesize webView = _webView;
@synthesize urlTextField = _urlTextField;
@synthesize serverCertificateButton = _serverCertificateButton;
@synthesize serverCertificateData = _serverCertificateData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)goToUrl:(UIButton *)sender
{
    [self.urlTextField resignFirstResponder];
    
    NSString *webConnectUrl = self.urlTextField.text;
    
    [ADVCertificator instance].delegate = self;
    self.serverCertificateData = nil;
    [self updateServerCertificateButton];
   
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webConnectUrl]]];
   
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.webView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.urlTextField.delegate = self;
    [self updateServerCertificateButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setUrlTextField:nil];
    [self setServerCertificateButton:nil];
    [self setServerCertificateLabel:nil];
    [super viewDidUnload];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewServerCertificateDetails"])
    {
        ADVCertificateViewController *certificateViewController = (ADVCertificateViewController *)segue.destinationViewController;
        [certificateViewController showCertificate:self.serverCertificateData];
    }
}


- (BOOL)textFieldShouldReturn: (UITextField*) tf
{
    [self goToUrl:nil];
    return YES;
}

-(void)updateServerCertificateButton
{
    if (self.serverCertificateData != nil)
    {
        ADVX509Certificate *serverCertificate = [ADVX509Certificate certificateWithData:self.serverCertificateData];
        if (serverCertificate != nil)
        {
            self.serverCertificateButton.enabled = YES;
            
            self.serverCertificateLabel.text = serverCertificate.commonName;
        }
    }
    else
    {
        self.serverCertificateLabel.text = nil;
        self.serverCertificateButton.enabled = NO;
    }
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"webView shouldStartLoadWithRequest %@", request);
    return YES;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webView didFailLoadWithError %@", error);
    [self updateServerCertificateButton];
    
    [webView loadHTMLString:[NSString stringWithFormat:@"<html><head></head><body><p style='color:red'>%@</p></body></html>", error.localizedDescription] baseURL:nil];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webView webViewDidFinishLoad");
    [self updateServerCertificateButton];
}

#pragma mark ADVCertificatorDelegate

-(ADVServerCertificateResponse)connection:(NSURLConnection *)connection verifyServerCertificate:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"verifyServerCertificate invoked");

    // Get the server certificate data for display
    SecCertificateRef remoteVersionOfServerCertificate = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, 0);
    self.serverCertificateData = (NSData *)CFBridgingRelease(SecCertificateCopyData(remoteVersionOfServerCertificate));
    
    //default response
    return ADVServerCertificateResponseDefault;
}

@end
