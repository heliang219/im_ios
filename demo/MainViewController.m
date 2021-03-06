//
//  MainViewController.m
//  NGChatSDK
//
//  Created by chisj on 14-10-17.
//  Copyright (c) 2014年 NGDS. All rights reserved.
//

#import "MainViewController.h"

#import <imsdk/IMService.h>
#import <imkit/TextMessageViewController.h>
#import <imkit/MessageViewController.h>
#import <imkit/IMHttpAPI.h>
#import <imkit/PeerMessageViewController.h>


@interface MainViewController (){
    UITextField *tfSender;
    UITextField *tfReceiver;
}

@property(nonatomic, weak)UIButton *chatButton;
@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    bgImageView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:bgImageView];
    
    float startHeight = [[UIScreen mainScreen] bounds].size.height >= 568.0 ? 180 : 100;
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [self.view addSubview:headerImageView];
    
    tfSender = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    tfSender.textColor = [UIColor whiteColor];
    tfSender.font = [UIFont systemFontOfSize:18];
    tfSender.placeholder = @"发送用户id";
    tfSender.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:tfSender];
    
    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [self.view addSubview:whiteLine];
    
    startHeight += 45;
    headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [self.view addSubview:headerImageView];
    
    tfReceiver = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    tfReceiver.textColor = [UIColor whiteColor];
    tfReceiver.font = [UIFont systemFontOfSize:18];
    tfReceiver.placeholder = @"接收用户id";
    tfReceiver.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:tfReceiver];
    
    whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [self.view addSubview:whiteLine];
    startHeight += 45 + ([[UIScreen mainScreen] bounds].size.height >= 568.0 ? 20 : 15);
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, startHeight, self.view.frame.size.width - 30, 48);
    [btn setTitle:@"登录" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    [btn addTarget:self action:@selector(actionChat) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.chatButton = btn;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}


- (void)actionChat {
    if (!tfSender.text.length || !tfReceiver.text.length) {
        NSLog(@"invalid input");
        return;
    }
    [self.view endEditing:YES];
    
    self.chatButton.userInteractionEnabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *token = [self login:[tfSender.text longLongValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chatButton.userInteractionEnabled = YES;
            
            if (token.length == 0) {
                NSLog(@"login fail");
                return;
            }
            
            NSLog(@"login success");
            

            PeerMessageViewController *msgController = [[PeerMessageViewController alloc] init];
            
            msgController.currentUID = [tfSender.text longLongValue];
            msgController.peerUID = [tfReceiver.text longLongValue];

            msgController.peerName = @"测试";

            [IMHttpAPI instance].accessToken = token;
            [[IMService instance] setToken:token];
            [[IMService instance] start];
            
            if (self.deviceToken.length > 0) {
                
                [IMHttpAPI bindDeviceToken:self.deviceToken
                                   success:^{
                                       NSLog(@"bind device token success");
                                   }
                                      fail:^{
                                          NSLog(@"bind device token fail");
                                      }];
            }
            
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:msgController animated:YES];
        });
    });
}

-(NSString*)login:(long long)uid {
    //调用app自身的登陆接口获取im服务必须的access token
    NSString *url = @"http://demo.im.gobelieve.io/auth/token";

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    
    
    [urlRequest setHTTPMethod:@"POST"];
    
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];

    [urlRequest setAllHTTPHeaderFields:headers];


    NSDictionary *obj = [NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:uid] forKey:@"uid"];
    NSData *postBody = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];

    [urlRequest setHTTPBody:postBody];

    NSURLResponse *response = nil;

    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"error:%@", error);
        return nil;
    }
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
    if (httpResp.statusCode != 200) {
        return nil;
    }
    NSDictionary *e = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    return [e objectForKey:@"token"];
}
@end