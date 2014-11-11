//
//  ViewController.h
//  PeerTest
//
//  Created by Felipe Saint-Jean on 11/10/14.
//  Copyright (c) 2014 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController : UIViewController <MCNearbyServiceAdvertiserDelegate,MCNearbyServiceBrowserDelegate,MCSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextView *console_view;
@property (weak, nonatomic) IBOutlet UITextView *messages_view;
@property (weak, nonatomic) IBOutlet UITextField *message_space;
@property (weak, nonatomic) IBOutlet UIButton *send_button;

@property (weak, nonatomic) IBOutlet UIView *accesoryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottom_constraint;
@property (weak, nonatomic) IBOutlet UILabel *status_label;
@property (weak, nonatomic) IBOutlet UILabel *peer_count_label;

@end

