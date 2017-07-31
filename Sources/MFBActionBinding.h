//
//  MFBActionBinding.h
//  Pods
//
//  Created by Nickolay Tarbayev on 28.07.2017.
//
//

#import <Foundation/Foundation.h>

#import "NSObject+MFBBindingAssertion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFBActionBinding : NSObject

@property (nonatomic, unsafe_unretained) IBOutlet id observable;
@property (nonatomic, copy) IBInspectable NSString *keyPath;

@property (nonatomic, unsafe_unretained) IBOutlet id target;
@property (nonatomic) IBInspectable NSString *action;

@end

@interface NSObject (MFBActionBinding)

- (void)mfb_bindAction:(SEL)action toObject:(id)observableController withKeyPath:(NSString *)keyPath;
- (void)mfb_unbindAction:(SEL)action;

@end

#ifdef DEBUG
/**
 For debug and assertion purposes only
 */
@interface NSObject (MFBActionBindingQueries)

/**
 @param keyPath The key-path, relative to the receiver, for which to return the list of corresponding bindings.
 */
- (NSArray *)mfb_triggeringBindingsForKeyPath:(NSString *)keyPath;

/**
 @param action A selector implemented by the receiver, for which to return the corresponding binding.
 */
- (id)mfb_bindingForAction:(SEL)action;

@end
#endif

// clang-format off
#if !defined(NS_BLOCK_ASSERTIONS)
    #define MFBAssertTriggerToActionBinding(obj, property) ({ \
        if (!obj.bindingAssertionDisabled) { \
            NSString *_propertyName = NSStringFromSelector(@selector(property)); \
            NSCAssert([obj mfb_triggeringBindingsForKeyPath:_propertyName].count > 0, \
                @"Missing action binding(s) for trigger: %@", _propertyName); \
        } \
    })
    #define MFBAssertActionToTriggerBinding(obj, action) ({ \
        if (!obj.bindingAssertionDisabled) { \
            NSCAssert([obj mfb_bindingForAction:action] != nil, \
                @"Missing trigger binding for action: %@", NSStringFromSelector(action)); \
        } \
    })
#else
    #define MFBAssertTriggerToActionBinding(obj, property) ({})
    #define MFBAssertActionToTriggerBinding(obj, property) ({})
#endif
// clang-format on

NS_ASSUME_NONNULL_END
