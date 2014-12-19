//
//  CLPMediaControl.m
//  Clappr
//
//  Created by Gustavo Barbosa on 12/18/14.
//  Copyright (c) 2014 globo.com. All rights reserved.
//

#import "CLPMediaControl.h"
#import "CLPContainer.h"

@implementation CLPMediaControl

#pragma mark - Ctors

- (instancetype)initWithContainer:(CLPContainer *)container
{
    self = [super init];
    if (self) {
        self.container = container;
    }
    return self;
}

#pragma mark - Accessors

- (void)setVolume:(float)volume
{
    if (volume < 0.0) {
        _volume = 0.0;
    } else if (volume > 100.0) {
        _volume = 100.0;
    } else {
        _volume = volume;
    }
}

#pragma mark - Methods

- (void)play
{
    [_container play];
}

@end
