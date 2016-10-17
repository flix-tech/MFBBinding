//
//  MFBBinding.h
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 01.08.16.
//
//

#import <Foundation/Foundation.h>

@interface MFBBinding : NSObject

@property (nonatomic, unsafe_unretained) IBOutlet id firstObject;
@property (nonatomic, copy) IBInspectable NSString *firstKeyPath;

@property (nonatomic, unsafe_unretained) IBOutlet id secondObject;
@property (nonatomic, copy) IBInspectable NSString *secondKeyPath;

@property (nonatomic, getter=isTwoWay) IBInspectable BOOL twoWay;
@property (nonatomic) IBInspectable BOOL retainsSecondObject;

@property (nonatomic) NSValueTransformer *valueTransformer;
@property (nonatomic, copy) IBInspectable NSString *valueTransformerName;

@end

extern NSString *const MFBTwoWayBindingOption;
extern NSString *const MFBRetainObserverBindingOption;
extern NSString *const MFBValueTransformerBindingOption;
extern NSString *const MFBValueTransformerNameBindingOption;

@interface NSObject (MFBBinding)

- (void)mfb_bind:(NSString *)binding
        toObject:(id)observableController
     withKeyPath:(NSString *)keyPath
         options:(NSDictionary<NSString *, id> *)options;

/**
 @param keyPath The key-path, relative to the receiver, for which to return the list of corresponding bindings.
 
 Important: Not optimised. Use for debugging or assertions only.
 */
- (NSArray<MFBBinding *> *)mfb_bindingsForKeyPath:(NSString *)keyPath;
- (NSArray<MFBBinding *> *)mfb_getterBindingsForKeyPath:(NSString *)keyPath;
- (NSArray<MFBBinding *> *)mfb_setterBindingsForKeyPath:(NSString *)keyPath;

/**
 Setting this property to @p YES will disable assertions made by @a MFBAssertGetterBinding and @a MFBAssertSetterBinding
 macros for the receiver.
 */
@property (nonatomic) BOOL bindingAssertionDisabled;

@end

#if !defined(NS_BLOCK_ASSERTIONS)
    #define MFBAssertGetterBinding(obj, property) ({ \
        if (!obj.bindingAssertionDisabled) { \
            NSString *_propertyName = NSStringFromSelector(@selector(property)); \
            NSCAssert([obj mfb_getterBindingsForKeyPath:_propertyName].count > 0, @"Missing getter binding(s) for property: %@", _propertyName); \
        }})
    #define MFBAssertSetterBinding(obj, property) ({ \
        if (!obj.bindingAssertionDisabled) { \
            NSString *_propertyName = NSStringFromSelector(@selector(property)); \
            NSCAssert([obj mfb_setterBindingsForKeyPath:_propertyName].count > 0, @"Missing setter binding(s) for property: %@", _propertyName); \
        }})
#else
    #define MFBAssertSetterBinding(obj, property)
    #define MFBAssertGetterBinding(obj, property)
#endif
