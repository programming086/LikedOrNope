//
// MDCSwipeToChooseView.m
//
//  Modified by Brovko Roman for support Up/down swipe for like/dislike
// Copyright (c) 2014 to present, Brian Gesiak @modocache
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "MDCSwipeToChooseView.h"
#import "MDCSwipeToChoose.h"
#import "MDCGeometry.h"
#import "UIView+MDCBorderedLabel.h"
#import "UIColor+MDCRGB8Bit.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const MDCSwipeToChooseViewHorizontalPadding = 10.f;
static CGFloat const MDCSwipeToChooseViewTopPadding = 20.f;
static CGFloat const MDCSwipeToChooseViewLabelWidth = 65.f;

@interface MDCSwipeToChooseView ()
@property (nonatomic, strong) MDCSwipeToChooseViewOptions *options;
@end

@implementation MDCSwipeToChooseView

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options {
    self = [super initWithFrame:frame];
    if (self) {
        _options = options ? options : [MDCSwipeToChooseViewOptions new];
        [self setupView];
        [self constructImageView];
        [self constructLikedView];
        [self constructNopeImageView];
        [self constructSuperLikedView];
        [self setupSwipeToChoose];
    }
    return self;
}

#pragma mark - Internal Methods

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 5.f;
    self.layer.borderWidth = 2.f;
    self.layer.borderColor = [UIColor colorWith8BitRed:220.f
                                                 green:220.f
                                                  blue:220.f
                                                 alpha:1.f].CGColor;
}

- (void)constructImageView {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.clipsToBounds = YES;
    [self addSubview:_imageView];
}

- (void)constructLikedView {
    MDCSwipeDirection directions = self.options.allowedSwipeDirections;
    BOOL isUpDownSwipeForLikeDislike = (directions & MDCSwipeDirectionUp) && (directions & MDCSwipeDirectionDown);
    
    CGFloat width = CGRectGetMidX(_imageView.bounds);
    CGFloat yOrigin = isUpDownSwipeForLikeDislike ? CGRectGetMaxY(_imageView.bounds) - MDCSwipeToChooseViewLabelWidth - MDCSwipeToChooseViewTopPadding : MDCSwipeToChooseViewTopPadding;
    CGFloat xOrigin = isUpDownSwipeForLikeDislike ? width / 2 : MDCSwipeToChooseViewHorizontalPadding;
    
    CGRect frame = CGRectMake(xOrigin, yOrigin, width, MDCSwipeToChooseViewLabelWidth);
    

    self.likedView = [[UIView alloc] initWithFrame:frame];
    [self.likedView constructBorderedLabelWithText:self.options.likedText
                                             color:self.options.likedColor
                                             angle:isUpDownSwipeForLikeDislike ? 0.0f : self.options.likedRotationAngle];
    self.likedView.alpha = 0.f;
    [self.imageView addSubview:self.likedView];
}

- (void)constructSuperLikedView {
    MDCSwipeDirection directions = self.options.allowedSwipeDirections;
    BOOL isUpDownSwipeForLikeDislike = (directions & MDCSwipeDirectionUp) && (directions & MDCSwipeDirectionDown);
    
    if (isUpDownSwipeForLikeDislike || !(directions & MDCSwipeDirectionUp)) {
        return;
    }
    
    CGFloat width = CGRectGetMidX(_imageView.bounds);
    CGFloat yOrigin = CGRectGetMaxY(_imageView.bounds) - 2 * MDCSwipeToChooseViewLabelWidth - MDCSwipeToChooseViewTopPadding;
    CGFloat xOrigin = width / 2;
    
    CGRect frame = CGRectMake(xOrigin, yOrigin, width, 2 * MDCSwipeToChooseViewLabelWidth);

    self.superLikedView = [[UIView alloc] initWithFrame:frame];
    [self.superLikedView constructBorderedLabelWithText:self.options.superLikedText
                                             color:self.options.superLikedColor
                                             angle:self.options.superLikedRotationAngle];
    self.superLikedView.alpha = 0.f;
    [self.imageView addSubview:self.superLikedView];

}

- (void)constructNopeImageView {
    MDCSwipeDirection directions = self.options.allowedSwipeDirections;
    BOOL isUpDownSwipeForLikeDislike = (directions & MDCSwipeDirectionUp) && (directions & MDCSwipeDirectionDown);
    
    CGFloat width = CGRectGetMidX(self.imageView.bounds);
    CGFloat xOrigin = isUpDownSwipeForLikeDislike ? width / 2 : CGRectGetMaxX(_imageView.bounds) - width - MDCSwipeToChooseViewHorizontalPadding;
    
    CGRect frame = CGRectMake(xOrigin,
                              MDCSwipeToChooseViewTopPadding,
                              width,
                              MDCSwipeToChooseViewLabelWidth);
    
    
    self.nopeView = [[UIImageView alloc] initWithFrame:frame];
    [self.nopeView constructBorderedLabelWithText:self.options.nopeText
                                            color:self.options.nopeColor
                                            angle:isUpDownSwipeForLikeDislike ? 0.0f : self.options.nopeRotationAngle];
    self.nopeView.alpha = 0.f;
    [self.imageView addSubview:self.nopeView];
}

- (void)setupSwipeToChoose {
    MDCSwipeOptions *options = [MDCSwipeOptions new];
    options.delegate = self.options.delegate;
    options.threshold = self.options.threshold;
    options.allowedSwipeDirections = self.options.allowedSwipeDirections;
    
    MDCSwipeDirection directions = self.options.allowedSwipeDirections;
    BOOL isUpDownSwipeForLikeDislike = (directions & MDCSwipeDirectionUp) && (directions & MDCSwipeDirectionDown);


    __block UIView *likedImageView = self.likedView;
    __block UIView *nopeImageView = self.nopeView;
    __block UIView *superLikedImageView = self.superLikedView;
    __weak MDCSwipeToChooseView *weakself = self;
  
    options.onPan = isUpDownSwipeForLikeDislike ? ^(MDCPanState *state) {
      
        if (state.direction == MDCSwipeDirectionNone ||
            state.direction == MDCSwipeDirectionLeft ||
            state.direction == MDCSwipeDirectionRight) {

            likedImageView.alpha = 0.f;
            nopeImageView.alpha = 0.f;
          
        } else if(state.direction == MDCSwipeDirectionUp) {
          
          likedImageView.alpha = state.thresholdRatio;
          nopeImageView.alpha = 0.f;
          
        } else if(state.direction == MDCSwipeDirectionDown) {
            
          likedImageView.alpha = 0.f;
          nopeImageView.alpha = state.thresholdRatio;
            
        }

        if (weakself.options.onPan) {
            weakself.options.onPan(state);
        }
    } : ^(MDCPanState *state) {
        
        if (state.direction == MDCSwipeDirectionNone ||
            state.direction == MDCSwipeDirectionDown) {
            
            likedImageView.alpha = 0.f;
            nopeImageView.alpha = 0.f;
            superLikedImageView.alpha = 0.f;
            
        } else if (state.direction == MDCSwipeDirectionLeft) {
            
            likedImageView.alpha = 0.f;
            nopeImageView.alpha = state.thresholdRatio;
            superLikedImageView.alpha = 0.f;
            
        } else if (state.direction == MDCSwipeDirectionRight) {
            
            likedImageView.alpha = state.thresholdRatio;
            nopeImageView.alpha = 0.f;
            superLikedImageView.alpha = 0.f;
            
        } else if(state.direction == MDCSwipeDirectionUp) {
            
            likedImageView.alpha = 0.f;
            nopeImageView.alpha = 0.f;
            superLikedImageView.alpha = state.thresholdRatio;
            
        }
        
        if (weakself.options.onPan) {
            weakself.options.onPan(state);
        }
    };

    [self mdc_swipeToChooseSetup:options];
}

@end
