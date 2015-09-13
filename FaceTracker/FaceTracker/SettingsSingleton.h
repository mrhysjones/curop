
//
//  SettingsSingleton.h
//  FaceTracker
//
//  Created by Matthew Jones on 12/09/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsSingleton : NSObject{
    BOOL fps;
    BOOL points;
    BOOL triangulation;
    BOOL connections;
    NSMutableArray * emotions;
}

@property (readwrite) BOOL fps; 
@property (readwrite) BOOL points;
@property (readwrite) BOOL triangulation;
@property (readwrite) BOOL connections;
@property (readwrite) NSMutableArray* emotions;

+(SettingsSingleton*)sharedMySingleton;

// Set booleans
-(void)toggleFPS:(BOOL) val;
-(void)togglePoints:(BOOL) val;
-(void)toggleTriangulation:(BOOL) val;
-(void)toggleConnections:(BOOL) val;
-(void)toggleEmotion:(BOOL) val index:(int)index;

// Access booleans
-(BOOL)getFPS;
-(BOOL)getPoints;
-(BOOL)getTriangulation;
-(BOOL)getConnections;
-(NSMutableArray*)getEmotions;

@end