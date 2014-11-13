//
//  MCViewController.m
//  MonsterChecker
//
//  Created by Mac on 12/09/14.
//  Copyright (c) 2014 sbrtech. All rights reserved.
//


typedef enum {
    AudioRunningstateActive = 0,
    AudioRunningstateinActive,
} AudioRunningstate;

#import "MCViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <sys/utsname.h>

#define ShowAlert(myTitle, myMessage) [[[UIAlertView alloc] initWithTitle:myTitle message:myMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show]

@protocol UzysImageCropperDelegate;
@class  UzysImageCropper;
@interface MCViewController ()<AVAudioPlayerDelegate,UITextViewDelegate>
{
    // Measurements
    CGFloat screenWidth;
    CGFloat screenHeight;
    CGFloat topX;
    CGFloat topY;
    
    // Resize Toggles
    BOOL isImageResized;
    BOOL isSaveWaitingForResizedImage;
    BOOL isRotateWaitingForResizedImage;
    
    // Capture Toggle
    BOOL isCapturingImage;
    
    CGPoint pos;
	UIImageView* fireBall;
    
    bool m_cameraSupported;
    
    UIImageView *Imageview;

}

@property (nonatomic,strong) UzysImageCropper *cropperView;
@property (nonatomic, assign) id <UzysImageCropperDelegate> delegate;
- (id)initWithImage:(UIImage*)newImage andframeSize:(CGSize)frameSize andcropSize:(CGSize)cropSize;

@property (nonatomic,retain) UIView *MainCameraBgView;

@property (assign) AudioRunningstate AudioRunningState;

// AVFoundation Properties
@property (strong, nonatomic) AVCaptureSession * mySesh;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureDevice * myDevice;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;

// View Properties
@property (strong, nonatomic) UIView * imageStreamV;
@property (strong, nonatomic) UIImageView * capturedImageV;
@property (nonatomic,retain) UIButton *ScanButton;

//

@property (nonatomic,retain) NSTimer *MyTimer;
@property (strong, nonatomic) AVAudioSession *audioSession;
@property (strong, nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@property (strong, nonatomic) AVAudioPlayer *backgroundMusicPlayerWarning;
@property (assign) BOOL backgroundMusicPlaying;
@property (assign) BOOL backgroundWaringMusicPlaying;
@property (assign) BOOL backgroundMusicInterrupted;
@property (nonatomic,retain) UIButton *ButtonStart;
@property (nonatomic,retain) UIButton *ButtonComplete;

@property (nonatomic,retain) UIImageView *NomonsterFoundImage;
@property (nonatomic,retain) UIButton *FacebookShareButton;
@property (nonatomic,retain) UIButton *TwitterShareButton;
@property (nonatomic,retain) SLComposeViewController *socialController;
@property (nonatomic,retain) UIButton *ScanButtonNew;

@property (nonatomic,retain) CAGradientLayer *gradient;

@end

@implementation MCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
           self =  [super initWithNibName:@"MCViewControllerIpad" bundle:nil];
        }
        else if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
        {
            CGSize result = [[UIScreen mainScreen] bounds].size;
            
            if (result.height == 480)
            {
                self =  [super initWithNibName:@"MCViewControllerSmall" bundle:nil];
            }
            else
            {
                self =  [super initWithNibName:@"MCViewController" bundle:nil];
            }
        }
    }
    return self;
}

- (void)viewDidLoad
{
    
    /*
     Set superview Load
     */
    
    [super viewDidLoad];
    
    /*
     Initiate main Cameraview
     */
    
    self.MainCameraBgView = [[UIView alloc] init];
    
    /*
     Hide Navigation Bar
     */
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    /*
     Add Gradient View in mainview background layer
     */
    
    _gradient = [CAGradientLayer layer];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _gradient.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.height+100, self.view.frame.size.width);
    } else {
        _gradient.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,self.view.frame.size.width, self.view.frame.size.height);
    }
    _gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor greenColor] CGColor],(id)[[UIColor blackColor] CGColor], nil];
    [self.view.layer insertSublayer:_gradient atIndex:0];
    
    /*
     Add Local notification center while device is rotated
     */
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    /*
     Add logo to the screen
     */
    
    UIImage *ImageNamed = [UIImage imageNamed:@"512x512.png"];
    UIImageView *LogoUIImageView = [[UIImageView alloc] init];
    
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [LogoUIImageView setFrame:CGRectMake(400, 8, 36, 36)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [LogoUIImageView setFrame:CGRectMake(160, 5, 22, 22)];
        }
        else
        {
            [LogoUIImageView setFrame:CGRectMake(200, 5, 22, 22)];
        }
    }
    [LogoUIImageView setBackgroundColor:[UIColor clearColor]];
    [LogoUIImageView setImage:ImageNamed];
    [self.view addSubview:LogoUIImageView];
    
    UILabel *MonsterHeading = [[UILabel alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [MonsterHeading setFrame:CGRectMake(440, 8, 100, 36)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [MonsterHeading setFrame:CGRectMake(185, 5, 100, 22)];
        }
        else
        {
            [MonsterHeading setFrame:CGRectMake(225, 5, 100, 22)];
        }
    }
    [MonsterHeading setBackgroundColor:[UIColor clearColor]];
    [MonsterHeading setTextColor:[UIColor whiteColor]];
    [MonsterHeading setText:@"Monster"];
    [MonsterHeading setFont:[UIFont fontWithName:@"Arial-BoldMT" size:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?22:16]];
    [self.view addSubview:MonsterHeading];
    
    UILabel *MonsterHeading1 = [[UILabel alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [MonsterHeading1 setFrame:CGRectMake(528, 9, 100, 36)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [MonsterHeading1 setFrame:CGRectMake(250, 6, 100, 22)];
        }
        else
        {
            [MonsterHeading1 setFrame:CGRectMake(290, 6, 100, 22)];
        }
    }
    [MonsterHeading1 setBackgroundColor:[UIColor clearColor]];
    [MonsterHeading1 setTextColor:[UIColor redColor]];
    [MonsterHeading1 setText:@"checker"];
    [MonsterHeading1 setFont:[UIFont fontWithName:@"Arial" size:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?20:14]];
    [self.view addSubview:MonsterHeading1];
    
    UILabel *MonsterFooter = [[UILabel alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [MonsterFooter setFrame:CGRectMake(420, 735, 400, 20)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [MonsterFooter setFrame:CGRectMake(160, 300, 200, 20)];
        }
        else
        {
            [MonsterFooter setFrame:CGRectMake(200, 300, 200, 20)];
        }
    }
    [MonsterFooter setBackgroundColor:[UIColor clearColor]];
    [MonsterFooter setText:@"2014 \u00A9 Monster Checker"];
    [MonsterFooter setFont:[UIFont fontWithName:@"Arial" size:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?20:12]];
    [MonsterFooter setTextColor:[UIColor whiteColor]];
    [self.view addSubview:MonsterFooter];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.MainCameraBgView setFrame:CGRectMake(self.view.frame.origin.x+100, self.view.frame.origin.y+50, self.view.frame.size.height-200, self.view.frame.size.width-100)];
    } else {
        [self.MainCameraBgView setFrame:CGRectMake(self.view.frame.origin.x+57, self.view.frame.origin.x+30, (IsIphone5)?self.view.frame.size.width-126:self.view.frame.size.width-110, self.view.frame.size.height-50)];
    }
    [self.MainCameraBgView setBackgroundColor:[UIColor blackColor]];
    [self.MainCameraBgView.layer setBorderWidth:1.0f];
    [self.MainCameraBgView.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.view addSubview:self.MainCameraBgView];
    
    _ScanButtonNew = [[UIButton alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [_ScanButtonNew setFrame:CGRectMake(915, 353, 90, 90)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [_ScanButtonNew setFrame:CGRectMake(430, 137, 42, 42)];
        }
        else
        {
            [_ScanButtonNew setFrame:CGRectMake(518, 139, 42, 42)];
        }
    }
    
    [_ScanButtonNew setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal];
    [_ScanButtonNew addTarget:self action:@selector(StartScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_ScanButtonNew];
    
    [self configureAudioSession];
    [self configureAudioPlayer];
    [self configureAudioPlayerwaring];
    
    [self CaptureImageViewForStaticImage];
    [self NoMonsterFoundImage];
    [self SocialShareSettings];
    [self addcameraView];
    [self CreateScanButton];
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput) {
        [captureSession addInput:audioInput];
    } else {
        NSLog(@"There is some error");
    }
    _AudioRunningState = AudioRunningstateinActive;
}

- (NSString *)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *temp = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([temp rangeOfString:@"iPod"].location != NSNotFound) {
        return @"iPod";
    } if ([temp rangeOfString:@"iPad"].location != NSNotFound) {
        return @"iPad";
    } if ([temp rangeOfString:@"iPhone"].location != NSNotFound) {
        return @"iPhone";
    }
    return @"Unknown device";
}


-(void)CreateScanButton
{
    _ScanButton = (UIButton *)[self.view viewWithTag:100];
    [_ScanButton addTarget:self action:@selector(StartScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view bringSubviewToFront:_ScanButton];
}

-(void)NoMonsterFoundImage
{
    _NomonsterFoundImage = [[UIImageView alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [_NomonsterFoundImage setFrame:CGRectMake(300, 350, 420, 80)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [_NomonsterFoundImage setFrame:CGRectMake(130, 140, 220, 40)];
        }
        else
        {
            [_NomonsterFoundImage setFrame:CGRectMake(175, 140, 220, 40)];
        }
    }
    [_NomonsterFoundImage setBackgroundColor:[UIColor clearColor]];
    [_NomonsterFoundImage setImage:[UIImage imageNamed:@"nomonsterfound.png"]];
    [self.view addSubview:_NomonsterFoundImage];
    [self.view bringSubviewToFront:_NomonsterFoundImage];
    [_NomonsterFoundImage setHidden:YES];
}

-(void)CaptureImageViewForStaticImage
{
    _capturedImageV = [[UIImageView alloc] init];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_capturedImageV setFrame:CGRectMake(self.view.frame.origin.x+100, self.view.frame.origin.y+50, self.view.frame.size.height-200, self.view.frame.size.width-100)];
    } else {
        [_capturedImageV setFrame:CGRectMake(self.view.frame.origin.x+57, self.view.frame.origin.x+30, (IsIphone5)?self.view.frame.size.width-126:self.view.frame.size.width-110, self.view.frame.size.height-50)];
    }
    [_capturedImageV.layer setBorderColor:[UIColor whiteColor].CGColor];
    [_capturedImageV.layer setBorderWidth:1.0f];
    [_capturedImageV setHidden:YES];
    [self.view addSubview:_capturedImageV];
}

-(void)SocialShareSettings
{
    self.FacebookShareButton = [[UIButton alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self.FacebookShareButton setFrame:CGRectMake(910, 46, 100, 50)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [self.FacebookShareButton setFrame:CGRectMake(425, 26, 60, 36)];
        }
        else
        {
            [self.FacebookShareButton setFrame:CGRectMake(512, 26, 60, 36)];
        }
    }
    [self.FacebookShareButton setBackgroundImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    [self.FacebookShareButton addTarget:self action:@selector(ShareOnFacebook) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.FacebookShareButton];
    
    self.TwitterShareButton = [[UIButton alloc] init];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self.TwitterShareButton setFrame:CGRectMake(910, 673, 100, 50)];
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            [self.TwitterShareButton setFrame:CGRectMake(425, 268, 60, 36)];
        }
        else
        {
            [self.TwitterShareButton setFrame:CGRectMake(512, 268, 60, 36)];
        }
    }
    [self.TwitterShareButton setBackgroundImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    [self.TwitterShareButton addTarget:self action:@selector(ShareOnTwitter) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.TwitterShareButton];
}

-(void)ShareOnFacebook
{
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        
        ShowAlert(@"Sorry",@"Your phone facebook settings is not enabled, please login to your facebook account first");
        
    } else {
        
        SLComposeViewController *fbController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbController setEditing:NO];
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
        {
            SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
                [fbController dismissViewControllerAnimated:YES completion:nil];
                switch(result){
                    case SLComposeViewControllerResultCancelled:
                    default:
                    {
                        NSLog(@"Cancelled.....");
                        
                    }
                        break;
                    case SLComposeViewControllerResultDone:
                    {
                        ShowAlert(@"Success",@"Successfully Posted on Facebook");
                    }
                        break;
                }};
            
            [fbController setInitialText:@"I just checked my child's room for monsters using MONSTER CHECKER -- Click here to Download the app"];
            [fbController addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/monster-checker/id925530443?ls=1&mt=8"]];
            UIImage *ImageOne = [UIImage imageNamed:@"512x512.png"];
            [fbController addImage:ImageOne];
            
            [fbController setCompletionHandler:completionHandler];
            [self presentViewController:fbController animated:YES completion:nil];
        }
    }
}

-(void)ShareOnTwitter
{
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        ShowAlert(@"Sorry",@"Your phone twitter settings is not enabled, please login to your twitter account first");
    } else {
        
        SLComposeViewController *TwController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [TwController setEditing:NO];
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
                [TwController dismissViewControllerAnimated:YES completion:nil];
                switch(result){
                    case SLComposeViewControllerResultCancelled:
                    default:
                    {
                        NSLog(@"Cancelled.....");
                        
                    }
                        break;
                    case SLComposeViewControllerResultDone:
                    {
                        ShowAlert(@"Success",@"Successfully Posted on Twitter");
                    }
                        break;
                }};
            
            [TwController setInitialText:@"I just checked my child's room for monsters using MONSTER CHECKER -- Click here to Download the app"];
            [TwController addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/monster-checker/id925530443?ls=1&mt=8"]];
            UIImage *ImageOne               = [UIImage imageNamed:@"512x512.png"];
            [TwController addImage:ImageOne];
            
            [TwController setCompletionHandler:completionHandler];
            [self presentViewController:TwController animated:YES completion:nil];
        }
    }
}

-(void)StartScan
{
    [_capturedImageV setImage:nil];
    [_NomonsterFoundImage setHidden:YES];
    if (_AudioRunningState == AudioRunningstateinActive) {
        isCapturingImage = NO;
        [self Startoperation];
        [_capturedImageV setHidden:YES];
        _AudioRunningState = AudioRunningstateActive;
        [_ScanButtonNew setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    } else {
        
        [self complete];
        [_capturedImageV setHidden:NO];
        // [_NomonsterFoundImage setHidden:NO];
        [self capturePhoto];
        _AudioRunningState = AudioRunningstateinActive;
        [_ScanButtonNew setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    _imageStreamV.alpha = 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)deallocCameraview
{
    [_mySesh stopRunning];
    _mySesh       = nil;
    
    [_imageStreamV removeFromSuperview];
    _imageStreamV = nil;
    
    [_captureVideoPreviewLayer removeFromSuperlayer];
    _captureVideoPreviewLayer = nil;
    
    _myDevice = nil;
    _stillImageOutput= nil;
}

-(void)addcameraView
{
    if (_imageStreamV == nil) _imageStreamV = [[UIView alloc]init];
    _imageStreamV.alpha = 0;
    _imageStreamV.frame = self.MainCameraBgView.bounds;
    [self.MainCameraBgView  addSubview:_imageStreamV];
    
    if (_mySesh == nil) _mySesh = [[AVCaptureSession alloc] init];
    _mySesh.sessionPreset = AVCaptureSessionPresetPhoto;
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_mySesh];
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _captureVideoPreviewLayer.frame = _imageStreamV.layer.bounds;
    
    [_imageStreamV.layer addSublayer:_captureVideoPreviewLayer];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices.count==0) {
        NSLog(@"SC: No devices found (for example: simulator)");
        return;
    }
    _myDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
    if ([_myDevice isFlashAvailable] && _myDevice.flashActive && [_myDevice lockForConfiguration:nil]) {        _myDevice.flashMode = AVCaptureFlashModeOff;
        [_myDevice unlockForConfiguration];
    }
    
    NSError * error = nil;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:_myDevice error:&error];
    if (!input) {
        NSLog(@"SC: ERROR: trying to open camera: %@", error);
    }
    [_mySesh addInput:input];
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    [_mySesh addOutput:_stillImageOutput];
    [_mySesh startRunning];
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
}

-(void)Startoperation
{
    NSLog(@"Startoperation");
    if ([self.backgroundMusicPlayerWarning isPlaying]) {
        [self StopBackgroundwaring];
    }
    pos = CGPointMake(11.0, 8.0);
    fireBall = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"1.png"]];
    fireBall.frame = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?CGRectMake(10, 10, 86, 86):CGRectMake(10, 10, 42, 42);
    
    [self.MainCameraBgView addSubview:fireBall];
    [self tryPlayMusic];
    self.MyTimer = [NSTimer scheduledTimerWithTimeInterval:(0.1) target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    
}

-(void)complete
{
    NSLog(@"complete");
    
    /*
     Make timer invalidate and clen the timer object
     */
    
    [self.MyTimer invalidate];
    self.MyTimer = nil;
    
    /*
     make fireball hidden from the screen and fireball object set clear
     */
    
    [fireBall removeFromSuperview];
    fireBall = nil;
    
    [self StopBackground];
    [self tryPlayWarning];
    
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    NSLog(@"interfaceOrientation ---%d",interfaceOrientation);
//
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}

-(void)onTimer {
    
    fireBall.center = CGPointMake(fireBall.center.x + pos.x, fireBall.center.y + pos.y);
    
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        if (fireBall.center.x > 750 || fireBall.center.x < 52)
            pos.x = -pos.x;
        if (fireBall.center.y > 620 || fireBall.center.y < 46)
            pos.y = -pos.y;
    }
    else
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        
        if (result.height == 480)
        {
            if (fireBall.center.x > 340 || fireBall.center.x < 28)
                pos.x = -pos.x;
            if (fireBall.center.y > 246 || fireBall.center.y < 26)
                pos.y = -pos.y;
        }
        else
        {
            if (fireBall.center.x > 430 || fireBall.center.x < 28)
                pos.x = -pos.x;
            if (fireBall.center.y > 246 || fireBall.center.y < 26)
                pos.y = -pos.y;
        }
    }
    [self.view bringSubviewToFront:fireBall];
}

- (void)tryPlayMusic {
    
    if (self.backgroundMusicPlaying || [self.audioSession isOtherAudioPlaying]) {
        return;
    }
    [self.backgroundMusicPlayer prepareToPlay];
    [self.backgroundMusicPlayer play];
    self.backgroundMusicPlaying = YES;
    
}

- (void)tryPlayWarning {
    
    if (self.backgroundMusicPlaying || [self.audioSession isOtherAudioPlaying]) {
        return;
    }
    [self.backgroundMusicPlayerWarning prepareToPlay];
    [self.backgroundMusicPlayerWarning play];
    [self.backgroundMusicPlayerWarning setNumberOfLoops:0];
    self.backgroundWaringMusicPlaying = YES;
    
}

-(void)StopBackground
{
    [self.backgroundMusicPlayer stop];
    self.backgroundMusicPlaying = NO;
}

-(void)StopBackgroundwaring
{
    [self.backgroundMusicPlayerWarning stop];
    self.backgroundWaringMusicPlaying = NO;
}

#pragma mark - Private

- (void) configureAudioSession {
    
    self.audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    if ([self.audioSession isOtherAudioPlaying]) {
        [self.audioSession setCategory:AVAudioSessionCategorySoloAmbient error:&setCategoryError];
        self.backgroundMusicPlaying = NO;
    } else {
        [self.audioSession setCategory:AVAudioSessionCategoryAmbient error:&setCategoryError];
    }
    if (setCategoryError) {
        NSLog(@"Error setting category! %ld", (long)[setCategoryError code]);
    }
}

- (void)configureAudioPlayerwaring {
    
    NSString *backgroundMusicPath = [[NSBundle mainBundle] pathForResource:@"nomonstersfound" ofType:@"mp3"];
    NSURL *backgroundMusicURL = [NSURL fileURLWithPath:backgroundMusicPath];
    NSError *Audioplayererror;
    self.backgroundMusicPlayerWarning = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&Audioplayererror];
    if (!Audioplayererror) {
        self.backgroundMusicPlayerWarning.delegate = self;
        self.backgroundMusicPlayerWarning.volume = 1.0;
        self.backgroundMusicPlayerWarning.numberOfLoops = -1;
    } else {
        NSLog(@"Error in configureAudioPlayerwaring");
    }
}

- (void)configureAudioPlayer {
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    NSString *backgroundMusicPath = [[NSBundle mainBundle] pathForResource:@"bb" ofType:@"wav"];
    NSURL *backgroundMusicURL = [NSURL fileURLWithPath:backgroundMusicPath];
    NSError *Audioplayererror;
    self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&Audioplayererror];
    if (!Audioplayererror) {
        self.backgroundMusicPlayer.delegate = self;
        self.backgroundMusicPlayer.volume = 1.0;
        self.backgroundMusicPlayer.numberOfLoops = -1;
    } else {
        NSLog(@"Error in configureAudioPlayer");
    }
}

- (void) capturePhoto {
    
    if (isCapturingImage) {
        return;
    }
    isCapturingImage = YES;
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         UIImage * capturedImage = [[UIImage alloc]initWithData:imageData scale:1];
         
         if (_myDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
             
             if ([[self machineName] isEqualToString:@"iPod"]) {
                 
                 // rear camera active
                 if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
                     CGImageRef cgRef = capturedImage.CGImage;
                     capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDownMirrored];
                 }
                 else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
                     CGImageRef cgRef = capturedImage.CGImage;
                     capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationUpMirrored];
                 }
                 
             } else {
                 
                 // rear camera active
                 if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
                     CGImageRef cgRef = capturedImage.CGImage;
                     capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationUp];
                 }
                 else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
                     CGImageRef cgRef = capturedImage.CGImage;
                     capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDown];
                 }
                 
             }
         }
         _capturedImageV.contentMode = UIViewContentModeScaleAspectFill;
         _capturedImageV.clipsToBounds = YES;
         [_capturedImageV setImage:capturedImage];
         [_NomonsterFoundImage setHidden:NO];
         capturedImage = nil;
         imageData = nil;
     }];
}
- (UIImage *)rotateImage:(UIImage *)image onDegrees:(float)degrees
{
    CGFloat rads = M_PI * degrees / 180;
    float newSide = MAX([image size].width, [image size].height);
    CGSize size =  CGSizeMake(newSide, newSide);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, newSide/2, newSide/2);
    CGContextRotateCTM(ctx, rads);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-[image size].width/2,-[image size].height/2,size.width, size.height),image.CGImage);
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;
}
#pragma mark - AVAudioPlayerDelegate methods

- (void) audioPlayerBeginInterruption: (AVAudioPlayer *) player {
    
    self.backgroundMusicInterrupted = YES;
    self.backgroundMusicPlaying = NO;
}

- (void) audioPlayerEndInterruption: (AVAudioPlayer *) player withOptions:(NSUInteger) flags{
    [self tryPlayMusic];
    self.backgroundMusicInterrupted = NO;
}

/*
 Add method for device orientation tracking
 */

-(IBAction)deviceOrientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
   // NSLog(@"deviceOrientationDidChange");
    
//    UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:@"Device Rotationm" message:@"Rotated" delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
//    [Alert show];
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    
}

@end
