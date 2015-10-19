//
//  RootViewController.m
//  360 Video Text
//
//  Created by Nathan Fennel on 10/18/15.
//  Copyright © 2015 Nathan Fennel. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.recordVideoButton];
//    [self.view addSubview:self.playVideoBackButton];
}

- (UIButton *)recordVideoButton {
    if (!_recordVideoButton) {
        _recordVideoButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f ,self.view.frame.size.height * 0.25f, 150.0f, 60.0f)];
        _recordVideoButton.center = self.view.center;
        [_recordVideoButton setTitle:@"Record New Video" forState:UIControlStateNormal];
        [_recordVideoButton addTarget:self
                               action:@selector(recordButtonTouched:)
                     forControlEvents:UIControlEventTouchUpInside];
        _recordVideoButton.backgroundColor = [UIColor redColor];
    }
    
    return _recordVideoButton;
}

- (void)recordButtonTouched:(UIButton *)button {
    [self presentViewController:[ViewController new] animated:YES completion:^{
        
    }];
}

- (UIButton *)playVideoBackButton {
    if (!_playVideoBackButton) {
        _playVideoBackButton =[[UIButton alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height * 0.75f, 150.0f, 60.0f)];
        
        [_playVideoBackButton setTitle:@"Play Video" forState:UIControlStateNormal];
        [_playVideoBackButton addTarget:self
                               action:@selector(playButtonTouched:)
                     forControlEvents:UIControlEventTouchUpInside];
        _playVideoBackButton.backgroundColor = [UIColor redColor];
    }
    
    return _playVideoBackButton;
}

- (void)playButtonTouched:(UIButton *)button {
    NSString *mystr=[[NSString alloc] initWithFormat:@"Homido360VRplayer://location?id=1"];
    NSURL *myurl=[[NSURL alloc] initWithString:mystr];
    [[UIApplication sharedApplication] openURL:myurl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
