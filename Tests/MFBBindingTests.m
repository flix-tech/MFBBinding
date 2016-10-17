//
//  MFBBindingTests.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 01.08.16.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <objc/message.h>
#import "MFBBinding.h"

@interface MFBBindingTestObjectA : NSObject
@property (nonatomic) id propertyA;
@end

@implementation MFBBindingTestObjectA
@end

@interface MFBBindingTestObjectB : NSObject
@property (nonatomic) id propertyB;
@end

@implementation MFBBindingTestObjectB
@end

@interface MFBBindingTestControl : UIControl
@property (nonatomic) id propertyC;
@end

@implementation MFBBindingTestControl

+ (BOOL)automaticallyNotifiesObserversOfPropertyC
{
    return NO;
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    // Action is not triggered in unit test environment, so we invoke action directly.

    void (*msgSend)(id, SEL, id) = (__typeof__(msgSend))objc_msgSend;
    msgSend(target, action, self);
}

@end

@interface MFBBindingTestsConfiguration : NSObject

@property (nonatomic, unsafe_unretained) id firstObject;
@property (nonatomic, copy) NSString *firstKeyPath;

@property (nonatomic, unsafe_unretained) id secondObject;
@property (nonatomic, copy) NSString *secondKeyPath;

@property (nonatomic) BOOL twoWay;
@property (nonatomic) BOOL retainsSecondObject;

@property (nonatomic) NSValueTransformer *valueTransformer;
@property (nonatomic, copy) IBInspectable NSString *valueTransformerName;

- (id)setUpBinding __attribute__((ns_returns_retained));

- (id)registerBinding __attribute__((ns_returns_retained));

@end

@implementation MFBBindingTestsConfiguration

- (id)setUpBinding
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)registerBinding
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end

@interface MFBBindingTestsIBConfiguration : MFBBindingTestsConfiguration
@end

@implementation MFBBindingTestsIBConfiguration

- (id)setUpBinding
{
    MFBBinding *binding = [self registerBinding];

    [binding awakeFromNib];

    return binding;
}

- (id)registerBinding
{
    MFBBinding *binding = [MFBBinding new];

    binding.firstObject = self.firstObject;
    binding.firstKeyPath = self.firstKeyPath;

    binding.secondObject = self.secondObject;
    binding.secondKeyPath = self.secondKeyPath;

    binding.twoWay = self.twoWay;
    binding.retainsSecondObject = self.retainsSecondObject;

    binding.valueTransformerName = self.valueTransformerName;
    binding.valueTransformer = self.valueTransformer;

    return binding;
}

@end

@interface MFBBindingTestsInCodeConfiguration : MFBBindingTestsConfiguration
@end

@implementation MFBBindingTestsInCodeConfiguration

- (id)setUpBinding
{
    return [self registerBinding];
}

- (id)registerBinding
{
    NSMutableDictionary *options = [NSMutableDictionary new];

    if (self.twoWay) {
        options[MFBTwoWayBindingOption] = @YES;
    }

    if (self.retainsSecondObject) {
        options[MFBRetainObserverBindingOption] = @YES;
    }

    if (self.valueTransformer) {
        options[MFBValueTransformerBindingOption] = self.valueTransformer;
    }

    if (self.valueTransformerName) {
        options[MFBValueTransformerNameBindingOption] = self.valueTransformerName;
    }

    [self.secondObject mfb_bind:self.secondKeyPath
                       toObject:self.firstObject
                    withKeyPath:self.firstKeyPath
                        options:options];

    id binding;

    @autoreleasepool {
        binding = [self.firstObject mfb_bindingsForKeyPath:self.firstKeyPath][0];
    }

    return binding;
}

@end

#pragma mark -

@interface MFBBindingTests : XCTestCase

@end

@implementation MFBBindingTests {
    MFBBindingTestObjectA *_objectA;
    MFBBindingTestObjectB *_objectB;

    MFBBindingTestsConfiguration *_configuration;
}

- (void)invokeTest
{
    NSArray *configurationClasses = @[
        [MFBBindingTestsIBConfiguration class],
        [MFBBindingTestsInCodeConfiguration class]
    ];

    for (Class configurationClass in configurationClasses) {
        _configuration = [configurationClass new];
        NSLog(@"Binding configuration class: %@", NSStringFromClass(configurationClass));
        [super invokeTest];
    }
}

- (void)setUp 
{
    [super setUp];

    _configuration.firstObject =
    _objectA = [MFBBindingTestObjectA new];

    _configuration.firstKeyPath = NSStringFromSelector(@selector(propertyA));

    _configuration.secondObject =
    _objectB = [MFBBindingTestObjectB new];

    _configuration.secondKeyPath = NSStringFromSelector(@selector(propertyB));
}


#pragma mark - Test Methods

- (void)test_changeFirstObjectProperty_SecondObjectPropertyChanged
{
    [_configuration setUpBinding];

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;

        _objectA.propertyA = Value;

        XCTAssertEqual(_objectB.propertyB, Value);
    }
}

- (void)test_changeSecondObjectProperty_OneWayBinding_FirstObjectPropertyNotChanged
{
    [_configuration setUpBinding];

    id InitialValueA = _objectA.propertyA;

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;

        _objectB.propertyB = Value;

        XCTAssertEqual(_objectA.propertyA, InitialValueA);
    }
}

- (void)test_changeSecondObjectProperty_TwoWayBinding_FirstObjectPropertyChanged
{
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;

        _objectB.propertyB = Value;

        XCTAssertEqual(_objectA.propertyA, Value);
    }
}

- (void)test_FirstObjectDeallocation_OneWayBinding_BindingDeallocated
{
    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _objectA;

    binding = nil;
    _objectA = nil;

    XCTAssertNil(WeakObjA);
    XCTAssertNil(WeakBinding);
}

- (void)test_SecondObjectDeallocation_OneWayBinding_BindingDeallocated
{
    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjB = _objectB;

    binding = nil;
    _objectB = nil;

    XCTAssertNil(WeakObjB);
    XCTAssertNil(WeakBinding);

    _objectA.propertyA = @"Some";
}

- (void)test_FirstObjectDeallocation_OneWayBindingNotFinished_BindingDeallocated
{
    id binding = [_configuration registerBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _objectA;

    binding = nil;
    _objectA = nil;

    XCTAssertNil(WeakObjA);
    XCTAssertNil(WeakBinding);
}

- (void)test_SecondObjectDeallocation_OneWayBindingNotFinished_BindingDeallocated
{
    id binding = [_configuration registerBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjB = _objectB;

    binding = nil;
    _objectB = nil;

    XCTAssertNil(WeakObjB);
    XCTAssertNil(WeakBinding);

    _objectA.propertyA = @"Some";
}

- (void)test_TwoWayBinding_BindingStaysAliveIfObjectsAreAlive
{
    _configuration.twoWay = YES;
    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;

    binding = nil;

    XCTAssertNotNil(WeakBinding);
}

- (void)test_TwoWayBinding_BindingDoesNotCauseRetainCycles
{
    _configuration.twoWay = YES;
    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _objectA;
    __weak id WeakObjB = _objectB;

    binding = nil;
    _objectA = nil;
    _objectB = nil;

    XCTAssertNil(WeakBinding);
    XCTAssertNil(WeakObjA);
    XCTAssertNil(WeakObjB);
}

- (void)test_SecondObjectDeallocation_TwoWayBinding_HandledCorrectly
{
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    __weak id WeakObjB = _objectB;

    _objectB = nil;

    XCTAssertNil(WeakObjB);

    _objectA.propertyA = @"Some";
}

- (void)test_RetainsSecondObject_SecondObjectStaysAliveIfFirstObjectIsAlive
{
    _configuration.retainsSecondObject = YES;
    [_configuration setUpBinding];

    __weak id WeakObjB = _objectB;

    _objectB = nil;

    XCTAssertNotNil(WeakObjB);
}

- (void)test_RetainsSecondObject_DoesNotCauseRetainCycles
{
    _configuration.retainsSecondObject = YES;

    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _objectA;
    __weak id WeakObjB = _objectB;

    binding = nil;
    _objectA = nil;
    _objectB = nil;

    XCTAssertNil(WeakBinding);
    XCTAssertNil(WeakObjA);
    XCTAssertNil(WeakObjB);
}

- (void)test_changeFirstObjectProperty_IsNilTransformerNameSpecified_SecondObjectPropertyChangedToTransformedValue
{
    NSString *const ValueTransformerName = NSIsNilTransformerName;

    _configuration.valueTransformerName = ValueTransformerName;
    [_configuration setUpBinding];

    NSValueTransformer *expectedTransformer = [NSValueTransformer valueTransformerForName:ValueTransformerName];

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;

        _objectA.propertyA = Value;

        XCTAssertEqualObjects(_objectB.propertyB, [expectedTransformer transformedValue:Value]);
    }
}

- (void)test_changeFirstObjectProperty_CustomTransformerSpecified_SecondObjectPropertyChangedToTransformedValue
{
    id transformerMock = OCMClassMock([NSValueTransformer class]);

    _configuration.valueTransformer = transformerMock;
    [_configuration setUpBinding];

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;
        const id TransformedValue = [NSObject new];

        OCMExpect([transformerMock transformedValue:Value]).andReturn(TransformedValue);

        _objectA.propertyA = Value;

        OCMVerifyAll(transformerMock);
        XCTAssertEqualObjects(_objectB.propertyB, TransformedValue);
    }
}

- (void)test_changeSecondObjectProperty_TwoWayAndCustomTransformerSpecified_FirstObjectPropertyChangedToTransformedValue
{
    id transformerMock = OCMClassMock([NSValueTransformer class]);

    _configuration.twoWay = YES;
    _configuration.valueTransformer = transformerMock;
    [_configuration setUpBinding];

    for (id v in @[ [NSObject new], [NSNull null] ]) {

        const id Value = v != [NSNull null] ? v : nil;
        const id TransformedValue = [NSObject new];

        OCMExpect([transformerMock reverseTransformedValue:Value]).andReturn(TransformedValue);

        _objectB.propertyB = Value;

        OCMVerifyAll(transformerMock);
        XCTAssertEqualObjects(_objectA.propertyA, TransformedValue);
    }
}

- (void)test_object_bindingsForKeypath_OneWay_ArrayWithBindingControllerReturned
{
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_bindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[ binding ]);
    XCTAssertEqualObjects([_objectB mfb_bindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[ binding ]);
}

- (void)test_object_bindingsForKeypath_TwoWay_ArrayWithBindingControllerReturned
{
    _configuration.twoWay = YES;
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_bindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[ binding ]);
    XCTAssertEqualObjects([_objectB mfb_bindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[ binding ]);
}

- (void)test_object_getterBindingsForKeypath_OneWay_ArrayWithBindingControllerReturned
{
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_getterBindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[ binding ]);
    XCTAssertEqualObjects([_objectB mfb_getterBindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[]);
}

- (void)test_object_getterBindingsForKeypath_TwoWay_ArrayWithBindingControllerReturned
{
    _configuration.twoWay = YES;
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_getterBindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[ binding ]);
    XCTAssertEqualObjects([_objectB mfb_getterBindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[ binding ]);
}

- (void)test_object_setterBindingsForKeypath_OneWay_ArrayWithBindingControllerReturned
{
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_setterBindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[]);
    XCTAssertEqualObjects([_objectB mfb_setterBindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[ binding ]);
}

- (void)test_object_setterBindingsForKeypath_TwoWay_ArrayWithBindingControllerReturned
{
    _configuration.twoWay = YES;
    id binding = [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    XCTAssertEqualObjects([_objectA mfb_setterBindingsForKeyPath:NSStringFromSelector(@selector(propertyA))], @[ binding ]);
    XCTAssertEqualObjects([_objectB mfb_setterBindingsForKeyPath:NSStringFromSelector(@selector(propertyB))], @[ binding ]);
}

- (void)test_bindingToUIControlObject_UpdatesBindedPropertyForValueChangedEvent
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    MFBBindingTestsConfiguration *configuration = _configuration;

    configuration.firstObject = control;
    configuration.firstKeyPath = NSStringFromSelector(@selector(propertyC));
    [configuration setUpBinding];

    for (id value in @[ [NSObject new], [NSObject new], [NSObject new] ]) {

        control.propertyC = value;
        XCTAssertNotEqualObjects(_objectB.propertyB, value); // Should be non KVO property

        [control sendActionsForControlEvents:UIControlEventValueChanged];

        XCTAssertEqualObjects(_objectB.propertyB, value);
    }
}

- (void)test_reverseBindingToUIControlObject_UpdatesBindedPropertyForValueChangedEvent
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.secondObject = control;
    _configuration.secondKeyPath = NSStringFromSelector(@selector(propertyC));

    _configuration.twoWay = YES;

    [_configuration setUpBinding];

    for (id value in @[ [NSObject new], [NSObject new], [NSObject new] ]) {

        control.propertyC = value;
        XCTAssertNotEqualObjects(_objectB.propertyB, value); // Should be non KVO property

        [control sendActionsForControlEvents:UIControlEventValueChanged];

        XCTAssertEqualObjects(_objectA.propertyA, value);
    }
}

- (void)test_bindingToUIControlObject_UpdatesBindedPropertyForEditingChangedEvent
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.firstObject = control;
    _configuration.firstKeyPath = NSStringFromSelector(@selector(propertyC));

    [_configuration setUpBinding];

    for (id value in @[ [NSObject new], [NSObject new], [NSObject new] ]) {

        control.propertyC = value;
        XCTAssertNotEqualObjects(_objectB.propertyB, value); // Should be non KVO property

        [control sendActionsForControlEvents:UIControlEventEditingChanged];

        XCTAssertEqualObjects(_objectB.propertyB, value);
    }
}

- (void)test_reverseBindingToUIControlObject_UpdatesBindedPropertyForEditingChangedEvent
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.secondObject = control;
    _configuration.secondKeyPath = NSStringFromSelector(@selector(propertyC));

    _configuration.twoWay = YES;

    [_configuration setUpBinding];

    for (id value in @[ [NSObject new], [NSObject new], [NSObject new] ]) {

        control.propertyC = value;
        XCTAssertNotEqualObjects(_objectA.propertyA, value); // Should be non KVO property

        [control sendActionsForControlEvents:UIControlEventEditingChanged];

        XCTAssertEqualObjects(_objectA.propertyA, value);
    }
}

- (void)test_SecondObjectDeallocation_BindingToUIControlObject_HandledCorrectly
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.firstObject = control;
    _configuration.firstKeyPath = NSStringFromSelector(@selector(propertyC));

    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjB = _objectB;

    binding = nil;
    _objectB = nil;

    XCTAssertNil(WeakBinding);
    XCTAssertNil(WeakObjB);

    [control sendActionsForControlEvents:UIControlEventValueChanged];
    [control sendActionsForControlEvents:UIControlEventEditingChanged];

    // It's not necessary, but we want to remove target from control anyway.
    XCTAssertEqual(control.allTargets.count, 0);
}

- (void)test_FirstObjectDeallocation_ReverseBindingToUIControlObject_HandledCorrectly
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.secondObject = control;
    _configuration.secondKeyPath = NSStringFromSelector(@selector(propertyC));

    _configuration.twoWay = YES;

    id binding = [_configuration setUpBinding];

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _objectA;

    binding = nil;
    _objectA = nil;

    XCTAssertNil(WeakBinding);
    XCTAssertNil(WeakObjA);

    [control sendActionsForControlEvents:UIControlEventValueChanged];
    [control sendActionsForControlEvents:UIControlEventEditingChanged];

    // It's not necessary, but we want to remove target from control anyway.
    XCTAssertEqual(control.allTargets.count, 0);
}

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionEnabled_Thows
{
#pragma push_macro("NS_BLOCK_ASSERTIONS")

    // Force-enabling foundation assertions
    #ifdef NS_BLOCK_ASSERTIONS
        #undef NS_BLOCK_ASSERTIONS
    #endif

    MFBBindingTestObjectA *object = [MFBBindingTestObjectA new];

    XCTAssertThrows(MFBAssertSetterBinding(object, propertyA));
    XCTAssertThrows(MFBAssertGetterBinding(object, propertyA));

    object.bindingAssertionDisabled = YES;
    object.bindingAssertionDisabled = NO;

    XCTAssertThrows(MFBAssertSetterBinding(object, propertyA));
    XCTAssertThrows(MFBAssertGetterBinding(object, propertyA));

#pragma pop_macro("NS_BLOCK_ASSERTIONS")
}

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionDisabled_DoesNotThow
{
#pragma push_macro("NS_BLOCK_ASSERTIONS")

    // Force-enabling foundation assertions
    #ifdef NS_BLOCK_ASSERTIONS
        #undef NS_BLOCK_ASSERTIONS
    #endif

    MFBBindingTestObjectA *object = [MFBBindingTestObjectA new];

    object.bindingAssertionDisabled = YES;

    XCTAssertNoThrow(MFBAssertSetterBinding(object, propertyA));
    XCTAssertNoThrow(MFBAssertGetterBinding(object, propertyA));

#pragma pop_macro("NS_BLOCK_ASSERTIONS")
}

@end
