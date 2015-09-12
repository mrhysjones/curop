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


// Switch value changed actions
- (IBAction)fpsToggle:(id)sender;
- (IBAction)pointsToggle:(id)sender;
- (IBAction)triangulationToggle:(id)sender;
- (IBAction)connectionToggle:(id)sender;

@end
