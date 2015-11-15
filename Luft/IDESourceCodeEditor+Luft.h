//
//  IDESourceCodeEditor+Luft.h
//  Luft
//
//  Created by Hugo Tunius on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "IDESourceCodeEditor.h"

@interface IDESourceCodeEditor (Luft)
+ (void)luft_initialize;

- (void)handleTextChange;
@end
