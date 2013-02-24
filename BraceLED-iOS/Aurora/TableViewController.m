//
//  TableViewController.m
//  SimpleControl
//
//  Created by Cheong on 7/11/12.
//  Copyright (c) 2012 RedBearLab. All rights reserved.
//

#import "TableViewController.h"
#import <Foundation/NSObjCRuntime.h>
#import <QuartzCore/QuartzCore.h>

#define SCAN_TIME 5.0
#define SCAN_UPDATE_CHECK 0.5

@interface TableViewController ()

@end

@implementation TableViewController

@synthesize ble;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    ble = [[BLE alloc] init];
    [ble controlSetup:1];
    ble.delegate = self;
    [self disableWidgets];
    
    advanceFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/FPS target:self selector:@selector(advanceFrame:) userInfo:nil repeats:YES];
    
    self.tableView.delaysContentTouches = NO;
    self.tableView.scrollEnabled = NO;
    
    [btnConnect setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnConnect.backgroundColor = [UIColor colorWithRed:0/255.0 green:35/255.0 blue:68/255.0 alpha:1.0];
    btnConnect.layer.borderColor = [UIColor blackColor].CGColor;
    btnConnect.layer.borderWidth = 1.0f;
    btnConnect.layer.cornerRadius = 8.0f;
    
    isConnected = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)disableWidgets
{
    chaseBtn.enabled = NO;
    chaseBtn.alpha = 0.4;
    gradientBtn.enabled = NO;
    gradientBtn.alpha = 0.4;

    paletteSlider.enabled = NO;
    speedSlider.enabled = NO;    
}

- (void)enableWidgets
{
    chaseBtn.enabled = YES;
    chaseBtn.alpha = 1;
    gradientBtn.enabled = YES;
    gradientBtn.alpha = 1;
    
    paletteSlider.enabled = YES;
    paletteSlider.value = 0.5;
    speedSlider.enabled = YES;
    speedSlider.value = 0.5;
}


#pragma mark - BLE delegate

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");

    btnConnect.backgroundColor = [UIColor colorWithRed:0/255.0 green:35/255.0 blue:68/255.0 alpha:1.0];
    [indConnecting stopAnimating];
    
    [self disableWidgets];
    isConnected = false;
}

// When connected, this will be called
-(void) bleDidConnect
{
    NSLog(@"->Connected");

    [indConnecting stopAnimating];

    [self enableWidgets];
    int paletteIndex = 0; //24; //arc4random() % NUM_PALETTES;

    paletteSlider.value = (float)paletteIndex / (NUM_PALETTES-1);
    isConnected = true;
}

-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
}

// When data is coming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"BT received: %d bytes", length);
}


#pragma mark - Actions

// Connect button will call to this
- (IBAction)btnScanForPeripherals:(id)sender
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.isConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            return;
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [btnConnect setEnabled:false];
    [ble findBLEPeripherals:SCAN_TIME];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)SCAN_UPDATE_CHECK target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    scanTimeRemaining = SCAN_TIME;
    
    [indConnecting startAnimating];
}

-(void) connectionTimer:(NSTimer *)timer
{
    [btnConnect setEnabled:true];
    
    if (ble.peripherals.count > 0) {
        btnConnect.backgroundColor = [UIColor colorWithRed:90/255.0 green:158/255.0 blue:148/255.0 alpha:1.0];
        [ble connectPeripheral:[ble.peripherals objectAtIndex:0]];

        // disable disconnect notifications
        [ble.CM connectPeripheral:[ble.peripherals objectAtIndex:0]
                          options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    } else if (scanTimeRemaining > 0) {
        [NSTimer scheduledTimerWithTimeInterval:(float)SCAN_UPDATE_CHECK target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
        scanTimeRemaining = MAX(0, scanTimeRemaining-SCAN_UPDATE_CHECK);
    } else {
        btnConnect.backgroundColor = [UIColor colorWithRed:0/255.0 green:35/255.0 blue:68/255.0 alpha:1.0];
        [indConnecting stopAnimating];
    }
}


// IBAction for changing the palette slider value
-(IBAction)palleteSliderChanged:(UISlider *)sender
{
    int value = (int) (sender.value * (NUM_PALETTES-1));

    NSString *baseString = @"Palette #";
    paletteLabel.text = [baseString stringByAppendingFormat: @"%d", value+1];
}

// IBAction for the end of a palette slider change
-(IBAction)paletteSliderDone:(UISlider *)sender
{
    //int value = (int) (sender.value * (NUM_PALETTES-1));
    //[self sendSetPalette:value];
}

// IBAction for changing the speed slider value
-(IBAction)speedSliderChanged:(UISlider *)sender
{
}


#pragma mark - LED stuff

-(void) initLEDs
{
    chaseIndex = 0;
}


-(void) advanceFrame:(NSTimer *)timer
{
    // updateDisplay
    [self updateDisplay];
    
    // send data here
    [self sendData];
}

-(void) updateDisplay
{
    chaseIndex += speedSlider.value;
    if (chaseIndex > NUM_LEDS) chaseIndex = 0;
    for (int i=0; i<NUM_LEDS; i++) {
        if (i == (int)chaseIndex) leds[i][0] = 255;
        else leds[i][0] = 0;
    }

}

-(void) sendData
{
    if (!isConnected) return;
    
    //NSLog(@"Sending data\n");
    
    for (int i=0; i<NUM_LEDS/4; i++) {
        buffer[0] = 4*3;
        buffer[1] = i*4;
        for (int j=0; j<4; j++) {
            buffer[j*3+2] = leds[j+i*4][0];
            buffer[j*3+3] = leds[j+i*4][1];
            buffer[j*3+4] = leds[j+i*4][2];
        }
        NSData *data = [[NSData alloc] initWithBytes:buffer length:(4*3+2)];
        [ble write:data];
        usleep(10000);
    }
    
}

@end
