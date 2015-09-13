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
@synthesize angrySwitch;
@synthesize contemptSwitch;
@synthesize disgustSwitch;
@synthesize happySwitch;
@synthesize fearSwitch;
@synthesize sadnessSwitch;
@synthesize surpriseSwitch;
@synthesize naturalSwitch;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    fpsSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"fpsValue" ];
    pointsSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"pointsValue" ] ;
    connectionSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"connectionValue" ] ;
    triangulationSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"triangulationValue" ] ;
    angrySwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"angryValue" ] ;
    contemptSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"contemptValue" ] ;
    disgustSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"disgustValue" ] ;
    happySwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"happyValue" ] ;
    fearSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"fearValue" ] ;
    sadnessSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"sadnessValue" ] ;
    surpriseSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"surpriseValue" ];
    naturalSwitch.on = [ [ NSUserDefaults standardUserDefaults ] boolForKey:@"naturalValue" ] ;
    
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

- (IBAction)angryToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:0    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:0    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:angrySwitch.on forKey:@"angryValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)contemptToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:1    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:1    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:contemptSwitch.on forKey:@"contemptValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)disgustToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:2    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:2    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:disgustSwitch.on forKey:@"disgustValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)fearToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:3    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:3    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:fearSwitch.on forKey:@"fearValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)happyToggle:(id)sender{
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:4    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:4    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:happySwitch.on forKey:@"happyValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



- (IBAction)sadnessToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:5    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:5    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:sadnessSwitch.on forKey:@"sadnessValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)surpriseToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:6   ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:6    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:surpriseSwitch.on forKey:@"surpriseValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)naturalToggle:(id)sender {
    if ([sender isOn]){
        [[SettingsSingleton sharedMySingleton] toggleEmotion:YES index:7    ];
    }
    else{
        [[SettingsSingleton sharedMySingleton] toggleEmotion:NO index:7    ];
    }
    [[NSUserDefaults standardUserDefaults] setBool:naturalSwitch.on forKey:@"naturalValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
