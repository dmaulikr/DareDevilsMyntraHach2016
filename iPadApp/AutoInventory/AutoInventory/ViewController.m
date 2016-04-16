//
//  ViewController.m
//  AutoInventory
//
//  Created by Himadri Jyoti on 16/04/16.
//  Copyright © 2016 Himadri Jyoti. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import <AVFoundation/AVFoundation.h>
#import <ZXingObjC/ZXDecodeHints.h>
#import <ZXingObjC/ZXCGImageLuminanceSource.h>
#import <ZXingObjC/ZXLuminanceSource.h>
#import <ZXingObjC/ZXHybridBinarizer.h>
#import <ZXingObjC/ZXBinaryBitmap.h>
#import <ZXingObjC/ZXMultiFormatReader.h>
#import <ZXingObjC/ZXGenericMultipleBarcodeReader.h>


@interface ViewController ()<UITabBarDelegate, UITableViewDataSource, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cardDataSource;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, weak) NSTimer *roboTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(40, 0, 0, 0)];
    
    self.cardDataSource = [NSMutableArray array];
    
    self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://10.0.12.209:8080/stream_simple.html"]]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Faield to load");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"Loaded");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.socket.delegate = nil;
    self.socket = nil;
    self.roboTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([self.socket isConnected]) {
        [self.socket disconnect];
    }
    
    [self.socket connectToHost:@"raspberrypi.local" onPort:6666 error:nil];
}

- (void)handleEnteredBackground:(id)Obj {
    NSLog(@"handleEnteredBackground");
    if([self.socket isConnected]) {
        [self.socket disconnect];
    }
}

- (void)writeSocketCommand:(NSString*)aCommand {
    [self.socket writeData:[aCommand dataUsingEncoding:NSUTF8StringEncoding] withTimeout:5 tag:-1];
}


#pragma mark - GCDAysncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Socket connected to host %@ on port %hu",host,port);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"Socket DISCONNECTED");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Socket WroteData");
}

#pragma mark - Button Actions
- (IBAction)fwd:(id)sender {
    [self writeSocketCommand:@"FWD"];
}

- (IBAction)fwdStop:(id)sender {
    [self writeSocketCommand:@"FWDSTOP"];
}

- (IBAction)bkwd:(id)sender {
    [self writeSocketCommand:@"BKWD"];
}

- (IBAction)bkwdStop:(id)sender {
    [self writeSocketCommand:@"BKWDSTOP"];
}

- (IBAction)left:(id)sender {
    [self writeSocketCommand:@"LEFT"];
}

- (IBAction)leftStop:(id)sender {
    [self writeSocketCommand:@"LEFTSTOP"];
}

- (IBAction)right:(id)sender {
    [self writeSocketCommand:@"RIGHT"];
}

- (IBAction)rightStop:(id)sender {
    [self writeSocketCommand:@"RIGHTSTOP"];
}

- (IBAction)didTapCameraButton:(id)sender {
    [self scanForCode];
}

- (IBAction)didToggleRobotSwitch:(id)sender {
    UISwitch *roboSwitch = (UISwitch *)sender;
    if (roboSwitch.on) {
        self.roboTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(scanForCode) userInfo:nil repeats:YES];
        [self.roboTimer fire];
    }
    else {
        [self.roboTimer invalidate];
        self.roboTimer = nil;
    }
}

- (void)scanForCode {
    NSMutableDictionary *cardInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    UIImage *image = [self captureWebView:self.webView];
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    
    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:&error];
    NSString *codeText = nil;
    if (result) {
        codeText = result.text;
    }
    
    if (codeText && ![self isCodeAlreadyExist:codeText]) {
        [cardInfo setObject:codeText forKey:@"text"];
        [cardInfo setObject:image forKey:@"image"];
        [self.cardDataSource addObject:cardInfo];
        [self.tableView reloadData];
    }
}

- (BOOL)isCodeAlreadyExist:(NSString *)codeString {
    for (NSDictionary *dict in self.cardDataSource) {
        if ([[dict objectForKey:@"text"] isEqualToString:codeString]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cardDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cardCell"];
    [cell setBackgroundColor:[UIColor clearColor]];
    UIImageView *imageView = [cell viewWithTag:101];
    imageView.layer.cornerRadius = 5.0f;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [UIColor blackColor].CGColor;
    imageView.layer.borderWidth = 1.0f;
    
    NSDictionary *cardInfo = [self.cardDataSource objectAtIndex:indexPath.row];
    UIImageView *capturedImageView = [cell viewWithTag:102];
    capturedImageView.image = cardInfo[@"image"];
    
    UILabel *codeLabel = [cell viewWithTag:103];
    codeLabel.text = cardInfo[@"text"];
    
    return cell;
}


- (UIImage*)captureWebView:(UIWebView*)webView {
    // capture webview
    UIImage *img = nil;
    UIGraphicsBeginImageContextWithOptions(webView.bounds.size, webView.scrollView.opaque, 0.0);
    {
        [webView.layer renderInContext: UIGraphicsGetCurrentContext()];
        img = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return img;
}

@end
