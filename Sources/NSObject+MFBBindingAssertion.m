//
//  NSObject+MFBBindingAssertion.m
//  Pods
//
//  Created by Nickolay Tarbayev on 31.07.2017.
//
//

#import <objc/runtime.h>

#import "NSObject+MFBBindingAssertion.h"

@implementation NSObject (MFBBindingAssertion)

- (BOOL)bindingAssertionDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBindingAssertionDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(bindingAssertionDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN);
}

@end
