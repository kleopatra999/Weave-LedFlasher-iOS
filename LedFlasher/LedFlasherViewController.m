/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <GoogleWeave/GWLCommandProtocol.h>
#import <GoogleWeave/GWLWeaveCommand.h>
#import <GoogleWeave/GWLWeaveTransport.h>

#import "AppDelegate.h"
#import "LedFlasherViewController.h"

@interface LedFlasherViewController ()

@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *led1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *led2Switch;
@property (weak, nonatomic) IBOutlet UISwitch *led3Switch;

@property (nonatomic) GWLWeaveTransport *transport;

@end

@implementation LedFlasherViewController

- (void)viewDidLoad {
  [self.navigationItem setHidesBackButton:YES];
  // Set the connection label to involve the device name.
  [_connectionLabel setText:[NSString stringWithFormat:@"Connected to %@", [_device name]]];

  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  GWLLoginController *loginController = appDelegate.loginController;
  [loginController
   getAuthorizer:^(id<GTMFetcherAuthorizationProtocol> authorizer, NSError *error) {
     if (error) {
       NSLog(@"An error occurred while retrieving the authorizer - %@", error);
     } else {
       // [START state]
       // Obtain a transport to the device. The best of local Wi-Fi and Cloud will be autoselected.
       self.transport =
       [GWLWeaveTransport transportForDevice:_device
                                  authorizer:authorizer];

       // Get the current state from the device.
       id<GWLWeaveTransport> txport = (id<GWLWeaveTransport>)_transport;
       [txport getStateForDevice:_device handler:^(NSDictionary *state, NSError *error) {
         if (error) {
           NSLog(@"An error occurred during device state retrieval - %@", error);
         } else {
           // Obtained device state.
           // [START_EXCLUDE]
           // Preset the switches to match the LEDs.
           NSArray *ledStates = [[state valueForKey:@"_ledflasher"] valueForKey:@"_leds"];
           [_led1Switch setOn:[ledStates[0] boolValue]];
           [_led2Switch setOn:[ledStates[1] boolValue]];
           [_led3Switch setOn:[ledStates[2] boolValue]];

           // Enable the switches.
           [_led1Switch setEnabled:YES];
           [_led2Switch setEnabled:YES];
           [_led3Switch setEnabled:YES];
           // [END_EXCLUDE]
         }
       }];
       // [END state]
     }
   }];
}

# pragma mark Switch actions

- (IBAction)ledSwitchValueChanged:(id)sender {
  // Determine which switch was changed.
  NSInteger ledNumber = [sender tag];
  // Set the state on the appropriate LED.
  [self setLed:ledNumber toState:[(UISwitch *)sender isOn]];
}

#pragma mark _ledflasher commands

- (void)setLed:(NSInteger)ledNum toState:(BOOL)state {
  // [START command-send]
  NSDictionary *commandParams =
      @{ @"_led" : @(ledNum), @"_on" : @(state)};
  GWLWeaveCommand *ledCommand = [[GWLWeaveCommand alloc] initWithPackageName:@"_ledflasher"
                                                                 commandName:@"_set"
                                                                  parameters:commandParams];
  id<GWLWeaveTransport> txport = (id<GWLWeaveTransport>)_transport;
  [txport execute:ledCommand
           device:_device
          handler:^(GWLWeaveCommandResult *result, NSError *error) {
      if (error) {
        NSLog(@"An error occurred during command execution - %@", error);
      }
  }];
  // [END command-send]
}

@end
