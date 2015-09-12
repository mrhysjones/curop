//
//  SettingsViewController.m
//  FaceTracker
//
//  Created by Matthew Jones on 07/09/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize fpsSwitch;
@synthesize pointsSwitch;
@synthesize triangulationSwitch;
@synthesize connectionSwitch;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    fpsSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"fpsValue" ];
    pointsSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"pointsValue" ] ;
    connectionSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"connectionValue" ] ;
    triangulationSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"triangulationValue" ] ;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fpsToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleFPS:YES];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleFPS:NO];
    }
    [[NSUserDefaults standardUserDefaults] setBool:fpsSwitch.isOn forKey:@"fpsValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

- (IBAction)pointsToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] togglePoints:YES];
    }
    else{
        [[SettingsSingleton sharedMySingleton] togglePoints:NO];
    }
    [[NSUserDefaults standardUserDefaults] setBool:pointsSwitch.on forKey:@"pointsValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (IBAction)triangulationToggle:(id)sender {
    
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleTriangulation:YES];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleTriangulation:NO];
    }
    [[NSUserDefaults standardUserDefaults] setBool:triangulationSwitch.on forKey:@"triangulationValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (IBAction)connectionToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleConnections:YES];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleConnections:NO];
    }
    [[NSUserDefaults standardUserDefaults] setBool:connectionSwitch.on forKey:@"connectionValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
