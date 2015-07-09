//
//  ViewController.m
//  PeerTest
//
//  Created by Felipe Saint-Jean on 11/10/14.
//  Copyright (c) 2014 Test. All rights reserved.
//

#define XXServiceType @"bcx-service"

#import "ViewController.h"
@interface ViewController ()
@property (nonatomic,strong) MCPeerID *localPeerID;
@property (nonatomic,strong) NSMutableArray *mutableBlockedPeers;
@property (nonatomic,strong) MCNearbyServiceBrowser *browser;
@property (nonatomic,strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic,strong) MCSession *session;

@property (nonatomic,assign) BOOL is_master;
@end

@implementation ViewController


//pe-(void)
-(void)setGoodStatus:(NSString *)status{

    if ([NSThread isMainThread]){
        self.status_label.backgroundColor = [UIColor greenColor];
        self.status_label.text = status;
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.status_label.backgroundColor = [UIColor greenColor];
            self.status_label.text = status;
        });
    
    }
    
}


-(void)setBadStatus:(NSString *)status{
    
    if ([NSThread isMainThread]){
        self.status_label.backgroundColor = [UIColor redColor];
        self.status_label.text = status;
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.status_label.backgroundColor = [UIColor redColor];
            self.status_label.text = status;
        });
        
    }
    
}


-(void)setStatus:(NSString *)status{
    
    if ([NSThread isMainThread]){
        self.status_label.backgroundColor = [UIColor whiteColor];
        self.status_label.text = status;
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.status_label.backgroundColor = [UIColor whiteColor];
            self.status_label.text = status;
        });
        
    }
    
}



-(void)log:(NSString *)text{
    NSLog(@"%@",text);
    
    if ([NSThread isMainThread]){
        self.console_view.text = [self.console_view.text stringByAppendingString:[NSString stringWithFormat:@"\n%@",text]];
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.console_view.text = [self.console_view.text stringByAppendingString:[NSString stringWithFormat:@"\n%@",text]];
            
        });
    }
}
-(void)closeSession{
    if (self.session){
        [self.session disconnect];
        self.session = nil;
    }
}
-(void)toggleMaster{
    if (self.advertiser){
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }

    if (self.session){
        [self.session disconnect];
        self.session = nil;
    }
    
    if (self.browser){
        [self.browser stopBrowsingForPeers];
        self.browser = nil;
    }
    
    self.peer_count_label.alpha = 0.0;
    if (self.is_master)
        [self startListening];
    else
        [self startAdvertising:nil];
    
}
- (IBAction)startAdvertising:(id)sender {
    
    self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    
    [self.browser stopBrowsingForPeers];
    
    [self closeSession];
    
    self.is_master = YES;
    self.peer_count_label.alpha = 1.0;
    self.peer_count_label.text = @"0";
    
    self.advertiser =
    [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                      discoveryInfo:@{@"type":@"master"}
                                        serviceType:XXServiceType];
    self.advertiser.delegate = self;
    
    [self.advertiser startAdvertisingPeer];
    self.send_button.enabled = YES;
    [self log:@"Start Advertising"];
    
    [self setStatus:@"Advertising"];
}

-(void)broadCast:(NSString *)bcast_message{
    
    [self log:[NSString stringWithFormat:@"Send message %@",[self.session connectedPeers]]];

    
    NSData *data =  [bcast_message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    if (![self.session sendData:data
                        toPeers:[self.session connectedPeers]
                       withMode:MCSessionSendDataReliable
                          error:&error]) {
        NSLog(@"[Error] %@", error);
        [self setBadStatus:[error localizedDescription]];
    }


}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.peer_count_label.alpha = 0.0;
    //[self.accesoryView removeFromSuperview];
    
    //self.messages_view.inputAccessoryView = self.accesoryView;
    
    [self.message_space becomeFirstResponder];
    self.mutableBlockedPeers = [NSMutableArray new];
    
    
    UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMaster)];
    
    gest.numberOfTapsRequired = 2;
    gest.numberOfTouchesRequired = 1;
    
    [self.view addGestureRecognizer:gest];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.console_view.text = @"";
    
    /*
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(broadCast)];
    swipe.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipe];
     */
    
    self.send_button.enabled = NO;
    [self startListening];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardDidShow:)
                   name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:)
                   name:UIKeyboardWillHideNotification object:nil];
    
    
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    //self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //self.scrollIndicatorInsets = self.contentInset;
    self.bottom_constraint.constant = 0.0;
    [UIView animateWithDuration:0.1 animations:^{
        [self.view setNeedsLayout];
    }];
}


- (void)keyboardDidShow:(NSNotification *)notification
{
    // keyboard frame is in window coordinates
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // convert own frame to window coordinates, frame is in superview's coordinates
    //CGRect ownFrame = [self.window convertRect:self.frame fromView:self.superview];
    
    // calculate the area of own frame that is covered by keyboard
    //CGRect coveredFrame = CGRectIntersection(ownFrame, keyboardFrame);
    
    // now this might be rotated, so convert it back
    //coveredFrame = [self.window convertRect:coveredFrame toView:self.superview];
    
    // set inset to make up for covered array at bottom
   // self.contentInset = UIEdgeInsetsMake(0, 0, coveredFrame.size.height, 0);
   // self.scrollIndicatorInsets = self.contentInset;
    
    self.bottom_constraint.constant = keyboardFrame.size.height;
    [UIView animateWithDuration:0.1 animations:^{
        [self.view setNeedsLayout];
    }];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)startListening{
    
    
    if (self.session){
        [self.session disconnect];
        self.session = nil;
    }
    
    if (self.browser){
        [self.browser stopBrowsingForPeers];
        self.browser = nil;
    }
    
    if (self.advertiser){
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
    
    self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    self.is_master = NO;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID serviceType:XXServiceType];
    self.browser.delegate = self;
    
    [self log:[NSString stringWithFormat:@"Start Listening%@",self.localPeerID.displayName]];
    [self.browser startBrowsingForPeers];
    [self setStatus:@"Listening"];
    

}
- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}


#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    [self log:[NSString stringWithFormat:@"received invitation %@",peerID.displayName]];
    
    if (!self.session){
    
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID
                                              securityIdentity:nil
                                          encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
    }
    
    
    invitationHandler(YES, self.session);
  }

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser
didNotStartBrowsingForPeers:(NSError *)error{

    NSLog(@"ERR %s %d", __FILE__,__LINE__);
    [self setBadStatus:@"didNotStartBrowsingForPeers"];
}

- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary *)info{
    [self log:[NSString stringWithFormat:@"Found Peer:%@ %@",peerID.displayName,info]];

    if (info != nil && info[@"type"]){
        NSString *type = (NSString *)info[@"type"];
        if ( [type isEqualToString:@"master"]){
            self.session = [[MCSession alloc] initWithPeer:self.localPeerID
                                                securityIdentity:nil
                                            encryptionPreference:MCEncryptionNone];
            
            [browser invitePeer:peerID toSession:self.session withContext:nil timeout:5.0];
            self.session.delegate = self;
            [self setStatus:@"Sending invite ..."];
        }
    
    }
    
}

- (void)browser:(MCNearbyServiceBrowser *)browser
       lostPeer:(MCPeerID *)peerID{
    [self log:[NSString stringWithFormat:@"Lost Peer:%@",peerID.displayName]];
    
    [self setStatus:[NSString stringWithFormat:@"Lost Peer:%@",peerID.displayName]];
    
}

-(void)showMessage:(NSString *)message{
    if ([NSThread isMainThread]){
        self.messages_view.text = [self.messages_view.text stringByAppendingString:@"\n"];
        self.messages_view.text = [self.messages_view.text stringByAppendingString:message];
        [self log:message];
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.messages_view.text = [self.messages_view.text stringByAppendingString:@"\n"];
            self.messages_view.text = [self.messages_view.text stringByAppendingString:message];
            [self log:message];
            
        });
    }
    
    
}

#pragma mark MCSessionDelegate

- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID{
    
    NSString *message =
    [[NSString alloc] initWithData:data
                          encoding:NSUTF8StringEncoding];
    
    
    [self showMessage:[NSString stringWithFormat:@"%@:%@",peerID.displayName,message]];
  
}

- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress{
    [self log:@"didStartReceivingResourceWithName"];
}

- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(NSError *)error{
    [self log:@"didFinishReceivingResourceWithName"];

}

-(void)updatePeerCount{
    
    if ([NSThread isMainThread]){
        self.peer_count_label.text = [NSString stringWithFormat:@"%d",[self.session.connectedPeers count]];
        
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.peer_count_label.text = [NSString stringWithFormat:@"%d",[self.session.connectedPeers count]];

        });
        
    }

}

- (void)session:(MCSession *)session
didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID{
    [self log:@"didReceiveStream"];
}
- (void)session:(MCSession *)session
           peer:(MCPeerID *)peerID
 didChangeState:(MCSessionState)state{
    NSString *stt = nil;
    
    switch (state) {
        case MCSessionStateNotConnected:
            stt = @"MCSessionStateNotConnected";
            break;
        case MCSessionStateConnecting:
            stt = @"MCSessionStateConnecting";

            break;
        case MCSessionStateConnected:
            stt = @"MCSessionStateConnected";

            break;
            
        default:
            break;
    }
   
    
    if (self.is_master){
        [self updatePeerCount];
    }else{
    
        if (state == MCSessionStateConnected){
            self.send_button.enabled = YES;
            [self setGoodStatus:@"Connected"];
            
        }else if (state == MCSessionStateConnecting){
            [self setGoodStatus:@"Connecting"];
            
        
        }else{
            self.send_button.enabled = NO;
            [self setBadStatus:@"Disconnected"];
            [self performSelector:@selector(startListening) withObject:nil afterDelay:1.0];
        }
        
    }
    
    [self log:[NSString stringWithFormat:@"didChangeState: %@ %@",peerID.displayName,stt]];
}

- (void)session:(MCSession *)session
didReceiveCertificate:(NSArray *)certificate
       fromPeer:(MCPeerID *)peerID
certificateHandler:(void (^)(BOOL accept))certificateHandler{
    [self log:@"didReceiveCertificate"];
    certificateHandler(YES);

}
- (IBAction)sentmessage:(id)sender {
    [self broadCast:self.message_space.text];
    [self showMessage:self.message_space.text];
    self.message_space.text = @"";
   
}
@end
