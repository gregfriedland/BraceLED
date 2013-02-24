//
//  TableViewController.h
//  SimpleControl
//
//  Created by Cheong on 7/11/12.
//  Copyright (c) 2012 RedBearLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

#define NUM_LEDS 32
#define FPS 10

@interface TableViewController : UITableViewController <BLEDelegate>
{
    
    IBOutlet UIButton *btnConnect;
    IBOutlet UIButton *chaseBtn;
    IBOutlet UIButton *gradientBtn;
    
    IBOutlet UISlider *paletteSlider;
    IBOutlet UISlider *speedSlider;
 
    IBOutlet UILabel *paletteLabel;
    IBOutlet UIActivityIndicatorView *indConnecting;
    
    float scanTimeRemaining;
    
    uint8_t leds[NUM_LEDS][3];
    uint8_t buffer[NUM_LEDS/4*3+3];
    NSTimer *advanceFrameTimer;
    
    double chaseIndex;
    boolean_t isConnected;
}

@property (strong, nonatomic) BLE *ble;

@end

#define NUM_PALETTES 201

