
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

// Allows other classes to read and to modify these values
@property (readwrite) BOOL fps; 
@property (readwrite) BOOL points;
@property (readwrite) BOOL triangulation;
@property (readwrite) BOOL connections;
@property (readwrite) NSMutableArray* emotions;

/*!
 @brief Method that restricts the instantiation of SettingsSingleton to one object
 
 @discussion If SettingsSingleton has already been allocated and initialised, the current instance will be returned, else a new instance will be created and that will be returned 
 
 @return SettingsSingleton  Current instance of SettingsSingleton
 */
+(SettingsSingleton*)sharedMySingleton;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*!
 @brief Sets the boolean value that controls FPS output
 
 @param val YES/NO depending on the value selected in the settings
 */
-(void)toggleFPS:(BOOL) val;


/*!
 @brief Sets the boolean value that controls whether face tracking points are displayed
 
 @param val YES/NO depending on the value selected in the settings
 */
-(void)togglePoints:(BOOL) val;


/*!
 @brief Sets the boolean value that controls whether face tracking triangulation is displayed
 
 @param val YES/NO depending on the value selected in the settings
 */
-(void)toggleTriangulation:(BOOL) val;


/*!
 @brief Sets the boolean value that controls whether face tracking connections are displayed
 
 @param val YES/NO depending on the value selected in the settings
 */
-(void)toggleConnections:(BOOL) val;

/*!
 @brief Sets the boolean value that controls whether a particular emotion prediction is displayed
 
 @discussion The boolean values for the 8 emotions are stored in an NSMutableArray. This method is called for them, and a value is set at the index that corresponds to that emotion
 
 @remark The emotions array is in the same fixed order as the rest the application
 
 @param val YES/NO depending on the value selected in the settings
 @param index   Position of the emotion in the emotions NSMutableArray
 */
-(void)toggleEmotion:(BOOL) val index:(int)index;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 /*!
 @brief Check if FPS output option has been enabled
 
 @return BOOL   YES/NO depending on if option has been enabled
 */
-(BOOL)getFPS;

 /*!
 @brief Check if tracking points option has been enabled
 
 @return BOOL   YES/NO depending on if option has been enabled
 */
-(BOOL)getPoints;
/*!
 @brief Check if triangulation option has been enabled
 
 @return BOOL   YES/NO depending on if option has been enabled
 */
-(BOOL)getTriangulation;

/*!
 @brief Check if connections option has been enabled
 
 @return BOOL   YES/NO depending on if option has been enabled
 */
-(BOOL)getConnections;

/*!
 @brief Check which emotions have been enabled
 
 @discussion The values of whether or not to display the prediction values for the 8 emotions are all stored in one array. This method will return an array of all of the emotions, with YES/NO bool values
 
 @return NSMutableArray An array where each element corresponds to if a particular emotion has been enabled
 */
-(NSMutableArray*)getEmotions;

@end