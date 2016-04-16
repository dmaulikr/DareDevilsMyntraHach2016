//
//  ViewController.m
//  AutoInventory
//
//  Created by Himadri Jyoti on 16/04/16.
//  Copyright © 2016 Himadri Jyoti. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<UITabBarDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GCDAsyncSocket *socket;

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.socket.delegate = nil;
    self.socket = nil;
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


#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

@end
