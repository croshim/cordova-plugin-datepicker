/*
  Phonegap DatePicker Plugin
  https://github.com/sectore/phonegap3-ios-datepicker-plugin  
  
  Copyright (c) Greg Allen 2011
  Additional refactoring by Sam de Freyssinet
  
  Rewrite by Jens Krause (www.websector.de)

  MIT Licensed
*/

#import "DatePicker.h"
#import <Cordova/CDV.h>

@interface DatePicker ()

@property (nonatomic) BOOL isVisible;
@property (nonatomic) UIDatePicker* datePicker;
@property (nonatomic) UIPopoverController *datePickerPopover;

@property (nonatomic) UIView *popupView;
@property (nonatomic) UIView *backgroundView;
@end

@implementation DatePicker

#pragma mark - UIDatePicker

- (void)show:(CDVInvokedUrlCommand*)command {
    NSMutableDictionary *options = [command argumentAtIndex:0];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self showForPhone: options];
  } else {
    [self showForPad: options];
  }   
}

- (BOOL)showForPhone:(NSMutableDictionary *)options {
  if(!self.isVisible){
    [self createViewForActionSheet:options];
    self.isVisible = TRUE;
  }
  return true;
}

- (BOOL)showForPad:(NSMutableDictionary *)options {
  if(!self.isVisible){
    self.datePickerPopover = [self createPopover:options];
    self.isVisible = TRUE;
  }
  return true;    
}

- (void)hide {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [UIView animateWithDuration:.2 animations:^{
            self.popupView.alpha = 0.0;
            self.backgroundView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.backgroundView removeFromSuperview];
            [self.popupView removeFromSuperview];
            self.popupView = nil;
            self.backgroundView = nil;
            self.isVisible = FALSE;
        }];
    } else {
        [self.datePickerPopover dismissPopoverAnimated:YES];
    }
}

- (void)doneAction:(id)sender {
  [self jsDateSelected];
  [self hide];
}


- (void)cancelAction:(id)sender {
  [self hide];
}


- (void)dateChangedAction:(id)sender {
  [self jsDateSelected];
}

#pragma mark - JS API

- (void)jsDateSelected {
  NSTimeInterval seconds = [self.datePicker.date timeIntervalSince1970];
  NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"%f\");", seconds];
  [super writeJavascript:jsCallback];
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.isVisible = FALSE;   
}

#pragma mark - Factory methods

- (void)createViewForActionSheet:(NSMutableDictionary *)options {
    UIView *targetView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];//self.webView.superview

    self.datePicker = [self createDatePicker:options frame:CGRectMake(0, 44, 0, 0)];
    [self updateDatePicker:options];

    CGFloat y = targetView.frame.size.height -  CGRectGetMaxY(self.datePicker.frame);
    self.popupView = [[UIView alloc] initWithFrame:(CGRect){0, y, targetView.frame.size.width, CGRectGetMaxY(self.datePicker.frame)}];
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.popupView.backgroundColor = [UIColor whiteColor];
    [self.popupView addSubview:self.datePicker];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        UIBarButtonItem * flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, targetView.frame.size.width, 44)];
        
        NSArray * barButtons = @[cancelButton,flexibleSpace,doneButton];
        [toolBar setBarStyle:UIBarStyleBlackOpaque];
        [toolBar setItems:barButtons];
        
        [self.popupView addSubview:toolBar];
    } else {
        UISegmentedControl *cancelButton = [self createCancelButton:options];
        [self.popupView addSubview:cancelButton];
        // done button
        UISegmentedControl *doneButton = [self createDoneButton:options];
        [self.popupView addSubview:doneButton];
    }

    self.backgroundView.alpha = 0.0;
    self.backgroundView.frame = targetView.frame;
    [targetView addSubview:self.backgroundView];
    [targetView addSubview:self.popupView];

    self.popupView.frame = (CGRect){0, targetView.frame.size.height, self.popupView.frame.size};
    [UIView animateWithDuration:.2 animations:^{
        self.backgroundView.alpha = 1.0;
        self.popupView.frame = (CGRect){0, y, self.popupView.frame.size};
    } completion:nil];
}

- (UIPopoverController *)createPopover:(NSMutableDictionary *)options {
    
  CGFloat pickerViewWidth = 320.0f;
  CGFloat pickerViewHeight = 216.0f;
  UIView *datePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerViewWidth, pickerViewHeight)];

  CGRect frame = CGRectMake(0, 0, 0, 0);
  self.datePicker = [self createDatePicker:options frame:frame];
  [self.datePicker addTarget:self action:@selector(dateChangedAction:) forControlEvents:UIControlEventValueChanged];

  [self updateDatePicker:options];
  [datePickerView addSubview:self.datePicker];

  UIViewController *datePickerViewController = [[UIViewController alloc]init];
  datePickerViewController.view = datePickerView;
  
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:datePickerViewController];
  popover.delegate = self;
  [popover setPopoverContentSize:CGSizeMake(pickerViewWidth, pickerViewHeight) animated:NO];
  
  CGFloat x = [[options objectForKey:@"x"] intValue];
  CGFloat y = [[options objectForKey:@"y"] intValue];
  CGRect anchor = CGRectMake(x, y, 1, 1);
  [popover presentPopoverFromRect:anchor inView:self.webView.superview  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];   
  
  return popover;
}

- (UIDatePicker *)createDatePicker:(NSMutableDictionary *)options frame:(CGRect)frame { 
  UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:frame];   
  if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
    datePicker.backgroundColor = [UIColor whiteColor];
  }   
  return datePicker;
}

- (void)updateDatePicker:(NSMutableDictionary *)options {
  NSDateFormatter *formatter = [self createISODateFormatter:k_DATEPICKER_DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];
  NSString *mode = [options objectForKey:@"mode"];
  NSString *dateString = [options objectForKey:@"date"];
  BOOL allowOldDates = NO;
  BOOL allowFutureDates = YES;
  NSString *minDateString = [options objectForKey:@"minDate"];
  NSString *maxDateString = [options objectForKey:@"maxDate"];
    
  if ([[options objectForKey:@"allowOldDates"] intValue] == 1) {
    allowOldDates = YES;
  }
    
  if ( !allowOldDates) {
    self.datePicker.minimumDate = [NSDate date];
  }
    
  if(minDateString){
    self.datePicker.minimumDate = [formatter dateFromString:minDateString];
  }
  
  if ([[options objectForKey:@"allowFutureDates"] intValue] == 0) {
    allowFutureDates = NO;
  }
    
  if ( !allowFutureDates) {
    self.datePicker.maximumDate = [NSDate date];
  }
    
  if(maxDateString){
    self.datePicker.maximumDate = [formatter dateFromString:maxDateString];
  }
    
    self.datePicker.date = [formatter dateFromString:dateString];
    
  if ([mode isEqualToString:@"date"]) {
    self.datePicker.datePickerMode = UIDatePickerModeDate;
  }
  else if ([mode isEqualToString:@"time"]) {
    self.datePicker.datePickerMode = UIDatePickerModeTime;
  } else {
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
  }
}

- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeZone:timezone];
  [dateFormatter setDateFormat:format];

  return dateFormatter;
}


- (UISegmentedControl *)createCancelButton:(NSMutableDictionary *)options {
  NSString *label = [options objectForKey:@"cancelButtonLabel"];
  UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:label]];

  NSString *tintColorHex = [options objectForKey:@"cancelButtonColor"];
  button.tintColor = [self colorFromHexString: tintColorHex];  
    
  button.momentary = YES;
  button.segmentedControlStyle = UISegmentedControlStyleBar;
  button.apportionsSegmentWidthsByContent = YES;
  
  CGSize size = button.bounds.size;
  button.frame = CGRectMake(5, 7.0f, size.width, size.height);
  
  [button addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventValueChanged];
    
  return button;
}

- (UISegmentedControl *)createDoneButton:(NSMutableDictionary *)options {
  NSString *label = [options objectForKey:@"doneButtonLabel"];
  UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:label]];
  NSString *tintColorHex = [options objectForKey:@"doneButtonColor"];
  button.tintColor = [self colorFromHexString: tintColorHex];

  button.momentary = YES;
  button.segmentedControlStyle = UISegmentedControlStyleBar;
  button.apportionsSegmentWidthsByContent = YES;
    
  CGSize size = button.bounds.size;
  CGFloat width = size.width;
  CGFloat height = size.height;
  CGFloat xPos = 320 - width - 5; // 320 == width of DatePicker, 5 == offset to right side hand
  button.frame = CGRectMake(xPos, 7.0f, width, height);
  
  [button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventValueChanged];

  return button;
}

// Helper method to convert a hex string into UIColor
// @see: http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end