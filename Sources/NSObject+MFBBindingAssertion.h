//
//  NSObject+MFBBindingAssertion.h
//  Pods
//
//  Created by Nickolay Tarbayev on 31.07.2017.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (MFBBindingAssertion)

/**
 Setting this property to @p YES will disable assertions made by @a MFBAssertGetterBinding and @a MFBAssertSetterBinding
 macros for the receiver.
 */
@property (nonatomic) BOOL bindingAssertionDisabled;


@end
