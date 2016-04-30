//
//  ViewController.m
//  aVideo
//
//  Created by SomeBoy on 16/4/30.
//  Copyright © 2016年 SomeBoy. All rights reserved.
//

#import "ViewController.h"
#import "AVViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 100, 100, 30);
    [button setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(pushNExt:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)pushNExt:(id)sender {
    AVViewController *vc = [[AVViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
