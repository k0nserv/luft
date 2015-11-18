//
//  SettingsWindowController.m
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "SettingsWindowController.h"

#import "LuftSettings.h"

@interface SettingsWindowController () <NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *lowerLimitTextField;
@property (weak) IBOutlet NSTextField *upperLimitTextField;

@property (weak) IBOutlet NSButton *onlyViewControllersCheckBox;
@property (weak) IBOutlet NSButton *blendWithSidebarCheckBox;


@property (weak) IBOutlet NSTextField *blendFactorTextField;

@property (weak) IBOutlet NSSlider *blendFactorSlider;

@property (weak) IBOutlet NSColorWell *goodColorPicker;
@property (weak) IBOutlet NSColorWell *warningColorPicker;
@property (weak) IBOutlet NSColorWell *badColorPicker;

@end

@implementation SettingsWindowController

#pragma mark - Life Cycle

- (void)windowDidLoad {
    [super windowDidLoad];

    [self setDefaults];
    [self.goodColorPicker addObserver:self forKeyPath:@"color" options:0 context:NULL];
    [self.warningColorPicker addObserver:self forKeyPath:@"color" options:0 context:NULL];
    [self.badColorPicker addObserver:self forKeyPath:@"color" options:0 context:NULL];
}

- (void)dealloc {
    [self.goodColorPicker removeObserver:self forKeyPath:@"color"];
    [self.warningColorPicker removeObserver:self forKeyPath:@"color"];
    [self.badColorPicker removeObserver:self forKeyPath:@"color"];
}

- (void)setDefaults {
    BOOL blendingEnabled = [[LuftSettings sharedSettings] blendWithSidebar];
    
    self.onlyViewControllersCheckBox.state = (NSCellStateValue)[[LuftSettings sharedSettings] onlyViewController];
    self.blendWithSidebarCheckBox.state = (NSCellStateValue)blendingEnabled;
    self.goodColorPicker.color = [[LuftSettings sharedSettings] goodColor];
    self.warningColorPicker.color = [[LuftSettings sharedSettings] warningColor];
    self.badColorPicker.color = [[LuftSettings sharedSettings] badColor];
    self.lowerLimitTextField.stringValue = [NSString stringWithFormat:@"%ld", [[LuftSettings sharedSettings] lowerLimit]];
    self.upperLimitTextField.stringValue = [NSString stringWithFormat:@"%ld", [[LuftSettings sharedSettings] upperLimit]];
    self.lowerLimitTextField.delegate = self;
    self.upperLimitTextField.delegate = self;
    self.blendFactorSlider.doubleValue = [[LuftSettings sharedSettings] blendFactor] * 100;
    self.blendFactorSlider.enabled = blendingEnabled;
    self.blendFactorTextField.enabled = blendingEnabled;
}

#pragma mark - Actions

- (IBAction)didChangeBlendFactorSlider:(id)sender {
    NSSlider *slider = sender;
    [[LuftSettings sharedSettings] setBlendFactor:slider.doubleValue / 100];
}

- (IBAction)didTapBlendWithSidebar:(NSButton *)sender {
    BOOL enabled = sender.state;
    [[LuftSettings sharedSettings] setBlendWithSidebar:enabled];
    self.blendFactorSlider.enabled = enabled;
    self.blendFactorTextField.enabled = enabled;
}

- (IBAction)didTapOnlyViewControllersCheckBox:(NSButton *)sender {
    [[LuftSettings sharedSettings] setOnlyViewControllers:sender.state];
}

- (IBAction)didTapResetDefaults:(NSButton *)sender {
    [[LuftSettings sharedSettings] resetDefaults];
    [self setDefaults];
}

#pragma mark - Setters

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.goodColorPicker) {
        [[LuftSettings sharedSettings] setGoodColor:self.goodColorPicker.color];
    }
    if (object == self.warningColorPicker) {
        [[LuftSettings sharedSettings] setWarningColor:self.warningColorPicker.color];
    }
    if (object == self.badColorPicker){
        [[LuftSettings sharedSettings] setBadColor:self.badColorPicker.color];
    }
}


#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if([notification object] == self.lowerLimitTextField) {
        [[LuftSettings sharedSettings] setLowerLimit:self.lowerLimitTextField.stringValue.integerValue];
    }
    if([notification object] == self.upperLimitTextField) {
        [[LuftSettings sharedSettings] setUpperLimit:self.upperLimitTextField.stringValue.integerValue];
    }
}

@end
