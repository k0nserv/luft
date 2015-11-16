//
//  Luft.h
//  Luft
//
//  Created by Hugo Tunius on 05/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import <AppKit/AppKit.h>

@class Luft;

static Luft *sharedPlugin;

@interface Luft : NSObject

+ (instancetype)sharedPlugin;
+ (NSMenuItem *)menuItem;

- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end