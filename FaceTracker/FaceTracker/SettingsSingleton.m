//
//  SettingsSingleton.m
//  FaceTracker
//
//  Created by Matthew Jones on 12/09/2015.
//  Copyright (c) 2015 Matthew Jones. All rights reserved.
//

#import "SettingsSingleton.h"


@implementation SettingsSingleton
static SettingsSingleton* _sharedMySingleton = nil;

+(SettingsSingleton*)sharedMySingleton{
    @synchronized([SettingsSingleton class]) {
        if (!_sharedMySingleton)
            [[self alloc] init];
        return _sharedMySingleton;
    }
    return nil;
}
+(id)alloc {
    @synchronized([SettingsSingleton class]) {
        NSAssert(_sharedMySingleton == nil, @"Attempted to allocate a second instance of a singleton.");
        _sharedMySingleton = [super alloc];
        return _sharedMySingleton;
    }
    return nil;
}

-(id)init{
    self = [super init];
    if (self != nil) {
        fps = NO;
        connections = YES;
        triangulation = YES;
        points = YES; 
    }
    return self;
}

-(BOOL)getFPS{
    return fps;
}


-(BOOL)getPoints{
    return points;
}

-(BOOL)getTriangulation{
    return triangulation;
}

-(BOOL)getConnections{
    return connections;
}

-(void)toggleFPS:(BOOL) val{
    fps = val;
}

-(void)togglePoints:(BOOL)val{
    points = val;
}

-(void)toggleTriangulation:(BOOL)val{
    triangulation = val;
}

-(void)toggleConnections:(BOOL)val{
    connections = val;
}


@end