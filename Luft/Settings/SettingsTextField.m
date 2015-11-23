//
//  SettingsTextField.m
//  Luft
//
//  Created by Duncan Cunningham on 11/18/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "SettingsTextField.h"

@implementation SettingsTextField

- (void)setEnabled:(BOOL)flag {
    [super setEnabled:flag];
    
    if (!flag) {
        [self setTextColor:[NSColor secondarySelectedControlColor]];
    } else {
        [self setTextColor:[NSColor controlTextColor]];
    }
}

@end
