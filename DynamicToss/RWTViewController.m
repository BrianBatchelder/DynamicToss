//
//  RWTViewController.m
//  DynamicToss
//
//  Created by Main Account on 7/13/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import "RWTViewController.h"

static const CGFloat kThrowingThreshold = 1000;
static const CGFloat kThrowingVelocityPadding = 35;
static const CGFloat kAnimationDelay = 0.75;

@interface RWTViewController ()
@property (nonatomic, weak) IBOutlet UIView *image;
@property (nonatomic, weak) IBOutlet UIView *redSquare;
@property (nonatomic, weak) IBOutlet UIView *blueSquare;

@property (nonatomic, assign) CGRect originalBounds;
@property (nonatomic, assign) CGPoint originalCenter;

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic) UIPushBehavior *pushBehavior;
@property (nonatomic) UIDynamicItemBehavior *itemBehavior;
@end

@implementation RWTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.originalBounds = self.image.bounds;
//    NSLog(@"%@",NSStringFromCGRect(self.originalBounds));
//    self.originalCenter = self.image.center;
//    NSLog(@"image center = %@",NSStringFromCGPoint(self.image.center));

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
}

//- (void) viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    NSLog(@"image center = %@",NSStringFromCGPoint(self.image.center));
//}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"viewDidLayoutSubviews");
    NSLog(@"image center = %@",NSStringFromCGPoint(self.image.center));
    self.originalBounds = self.image.bounds;
    NSLog(@"%@",NSStringFromCGRect(self.originalBounds));
    self.originalCenter = self.image.center;
    NSLog(@"image center = %@",NSStringFromCGPoint(self.image.center));
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (IBAction) handleAttachmentGesture:(UIPanGestureRecognizer*)gesture
{
    CGPoint location = [gesture locationInView:self.view];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            NSLog(@"image center = %@",NSStringFromCGPoint(self.image.center));

            NSLog(@"your initial touch position = %@",NSStringFromCGPoint(location));
            CGPoint boxLocation = [gesture locationInView:self.image];
            NSLog(@"your initial image position = %@",NSStringFromCGPoint(boxLocation));
            
            [self.animator removeAllBehaviors];
            
            // Create an attachment binding the anchor point (the finger's current location)
            // to a certain position on the view (the offset)
            UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.image.bounds),
                                                 boxLocation.y - CGRectGetMidY(self.image.bounds));
            NSLog(@"centerOffset = %@",NSStringFromUIOffset(centerOffset));
            self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.image
                                                                offsetFromCenter:centerOffset
                                                                attachedToAnchor:location];
            
            // Update the red and blue boxes, so we can see the
            // touch start in blue and the anchor point in red
            self.redSquare.center = self.attachmentBehavior.anchorPoint;
            self.blueSquare.center = location;
            
            // Tell the animator to use this attachment behavior
            [self.animator addBehavior:self.attachmentBehavior];
            
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSLog(@"your final touch position = %@",NSStringFromCGPoint(location));
            CGPoint boxLocation = [gesture locationInView:self.image];
            NSLog(@"your final image position = %@",NSStringFromCGPoint(boxLocation));
            
            [self.animator removeBehavior:self.attachmentBehavior];
            
            //1
            CGPoint velocity = [gesture velocityInView:self.view];
            NSLog(@"velocity = %@",NSStringFromCGPoint(velocity));
            CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
            NSLog(@"magnitude = %f",magnitude);
            if (magnitude > kThrowingThreshold) {
                //2
                UIPushBehavior *pushBehavior = [[UIPushBehavior alloc]
                                                initWithItems:@[self.image]
                                                mode:UIPushBehaviorModeInstantaneous];
                pushBehavior.pushDirection = CGVectorMake((velocity.x / 10) , (velocity.y / 10));
                pushBehavior.magnitude = magnitude / kThrowingVelocityPadding;
                
                self.pushBehavior = pushBehavior;
                [self.animator addBehavior:self.pushBehavior];
                
                //3
                NSInteger angle = arc4random_uniform(20) - 10;
                
                self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.image]];
                self.itemBehavior.friction = 0.2;
                self.itemBehavior.allowsRotation = YES;
                [self.itemBehavior addAngularVelocity:angle forItem:self.image];
                [self.animator addBehavior:self.itemBehavior];
                
                //4
                [self performSelector:@selector(resetDemo) withObject:nil afterDelay:kAnimationDelay];
            }
            
            else {
                [self resetDemo];
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
//            NSLog(@"your current touch position %@",NSStringFromCGPoint(location));
            [self.attachmentBehavior setAnchorPoint:location];
            self.redSquare.center = self.attachmentBehavior.anchorPoint;
            break;
        }
        default: {
            NSLog(@"%ld",(long)gesture.state);
            assert(0);
        }
    }
}

- (void)resetDemo
{
    NSLog(@"Starting reset = %@, %@",NSStringFromCGPoint(self.image.center),NSStringFromCGRect(self.image.bounds));
    CGPoint newCenter = self.image.center;
    CGRect  newBounds = self.image.bounds;
    
    self.image.center = newCenter;
    self.image.bounds = newBounds;
    
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:kAnimationDelay animations:^{
        [self.view layoutIfNeeded];
        // UIDynamics doesn't use .frame, it uses .center & .bounds like CALayers do.
        NSLog(@"Starting animation");
        NSLog(@"from = %@, %@",NSStringFromCGPoint(self.image.center),NSStringFromCGRect(self.image.bounds));
        NSLog(@"to   = %@, %@",NSStringFromCGPoint(self.originalCenter),NSStringFromCGRect(self.originalBounds));
        self.image.bounds = self.originalBounds;
        self.image.center = self.originalCenter;
        self.image.transform = CGAffineTransformIdentity;
    }];

    // This will kill an existing push too
    [self.animator removeAllBehaviors];
    
}

@end
