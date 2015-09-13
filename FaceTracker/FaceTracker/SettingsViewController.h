//
//  SettingsViewController.h
//  FaceTracker
//
//  Created by Matthew Jones on 07/09/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "SettingsSingleton.h"

@interface SettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>;

// Switch outlets
@property (strong, nonatomic) IBOutlet UISwitch *fpsSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *pointsSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *triangulationSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *connectionSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *angrySwitch;
@property (strong, nonatomic) IBOutlet UISwitch *contemptSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *disgustSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *happySwitch;
@property (strong, nonatomic) IBOutlet UISwitch *fearSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *sadnessSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *surpriseSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *naturalSwitch;


// General settings toggled
- (IBAction)fpsToggle:(id)sender;

//Drawing settings toggled
- (IBAction)pointsToggle:(id)sender;
- (IBAction)triangulationToggle:(id)sender;
- (IBAction)connectionToggle:(id)sender;

// Classification settings toggled
- (IBAction)angryToggle:(id)sender;
- (IBAction)contemptToggle:(id)sender;
- (IBAction)disgustToggle:(id)sender;
- (IBAction)happyToggle:(id)sender;
- (IBAction)fearToggle:(id)sender;
- (IBAction)sadnessToggle:(id)sender;
- (IBAction)surpriseToggle:(id)sender;
- (IBAction)naturalToggle:(id)sender;


@end
