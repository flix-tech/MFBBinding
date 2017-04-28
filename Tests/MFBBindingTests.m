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
#import <MFBBinding/MFBBinding.h>

@interface MFBBindingTestObjectA : NSObject
@property (nonatomic) id propertyA;
@property (nonatomic, copy) NSArray *arrayA;
@property (nonatomic, copy) NSArray *fineGrainedArrayA;

@property (nonatomic, readonly) NSArray *insertedObjects;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *removedIndexes;
@property (nonatomic, readonly) NSArray *replacingObjects;
@property (nonatomic, readonly) NSIndexSet *replacedIndexes;

@end

@implementation MFBBindingTestObjectA {
    NSMutableArray *_mutableArrayA;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableArrayA = [NSMutableArray new];
    }
    return self;
}

- (NSArray *)fineGrainedArrayA
{
    return _mutableArrayA;
}

- (void)setFineGrainedArrayA:(NSArray *)arrayA
{
    _mutableArrayA.array = arrayA;
}

- (void)insertFineGrainedArrayA:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_mutableArrayA insertObjects:array atIndexes:indexes];
    _insertedObjects = [array copy];
    _insertedIndexes = [indexes copy];
}

- (void)removeFineGrainedArrayAAtIndexes:(NSIndexSet *)indexes
{
    [_mutableArrayA removeObjectsAtIndexes:indexes];
    _removedIndexes = [indexes copy];
}

- (void)replaceFineGrainedArrayAAtIndexes:(NSIndexSet *)indexes withFineGrainedArrayA:(NSArray *)array
{
    [_mutableArrayA replaceObjectsAtIndexes:indexes withObjects:array];
    _replacingObjects = [array copy];
    _replacedIndexes = [indexes copy];
}

@end

@interface MFBBindingTestObjectB : NSObject
@property (nonatomic) id propertyB;
@property (nonatomic, copy) NSArray *arrayB;
@property (nonatomic, copy) NSArray *fineGrainedArrayB;

@property (nonatomic, readonly) NSArray *insertedObjects;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *removedIndexes;
@property (nonatomic, readonly) NSArray *replacingObjects;
@property (nonatomic, readonly) NSIndexSet *replacedIndexes;

@end

@implementation MFBBindingTestObjectB {
    NSMutableArray *_mutableArrayB;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableArrayB = [NSMutableArray new];
    }
    return self;
}

- (NSArray *)fineGrainedArrayB
{
    return _mutableArrayB;
}

- (void)setFineGrainedArrayB:(NSArray *)fineGrainedArrayB
{
    _mutableArrayB.array = fineGrainedArrayB;
}

- (void)insertFineGrainedArrayB:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_mutableArrayB insertObjects:array atIndexes:indexes];
    _insertedObjects = [array copy];
    _insertedIndexes = [indexes copy];
}

- (void)removeFineGrainedArrayBAtIndexes:(NSIndexSet *)indexes
{
    [_mutableArrayB removeObjectsAtIndexes:indexes];
    _removedIndexes = [indexes copy];
}

- (void)replaceFineGrainedArrayBAtIndexes:(NSIndexSet *)indexes withFineGrainedArrayB:(NSArray *)array
{
    [_mutableArrayB replaceObjectsAtIndexes:indexes withObjects:array];
    _replacingObjects = [array copy];
    _replacedIndexes = [indexes copy];
}

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

#pragma mark - Value Binding Test Methods

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


#pragma mark - Retaining Binding Test Methods

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


#pragma mark - Transforming Binding Test Methods

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


#pragma mark - Binding Query Test Methods

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


#pragma mark - UIControl Binding Test Methods

- (void)test_bindingToUIControlObject_UpdatesBoundPropertyForValueChangedEvent
{
    MFBBindingTestControl *control = [MFBBindingTestControl new];
    XCTAssertTrue([control isKindOfClass:[UIControl class]]);

    _configuration.firstObject = control;
    _configuration.firstKeyPath = NSStringFromSelector(@selector(propertyC));
    [_configuration setUpBinding];

    for (id value in @[ [NSObject new], [NSObject new], [NSObject new] ]) {

        control.propertyC = value;
        XCTAssertNotEqualObjects(_objectB.propertyB, value); // Should be non KVO property

        [control sendActionsForControlEvents:UIControlEventValueChanged];

        XCTAssertEqualObjects(_objectB.propertyB, value);
    }
}

- (void)test_reverseBindingToUIControlObject_UpdatesBoundPropertyForValueChangedEvent
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

- (void)test_bindingToUIControlObject_UpdatesBoundPropertyForEditingChangedEvent
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

- (void)test_reverseBindingToUIControlObject_UpdatesBoundPropertyForEditingChangedEvent
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


#pragma mark - Binding Assertions Test Methods

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


#pragma mark - Array Binding Test Methods

- (void)test_insertionIntoFirstObjectArray_ChangesSecondObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(arrayB));
    [_configuration setUpBinding];

    NSMutableArray *insertedObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int InsertedObjectsCount = arc4random_uniform(5) + 1;

    for (int i = 0; i < InsertedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount + InsertedObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [insertedObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.arrayB);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] insertObjects:insertedObjects atIndexes:indexes];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertEqualObjects(_objectB.arrayB, finalObjects);
}

- (void)test_removalInFirstObjectArray_ChangesSecondObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(arrayB));
    [_configuration setUpBinding];

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int RemovedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < RemovedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.arrayB);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] removeObjectsAtIndexes:indexes];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects removeObjectsAtIndexes:indexes];

    XCTAssertEqualObjects(_objectB.arrayB, finalObjects);
}

- (void)test_replacementInFirstObjectArray_ChangesSecondObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(arrayB));
    [_configuration setUpBinding];

    NSMutableArray *replacingObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int ReplacedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < ReplacedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [replacingObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.arrayB);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects replaceObjectsAtIndexes:indexes withObjects:replacingObjects];
    
    XCTAssertEqualObjects(_objectB.arrayB, finalObjects);
}

- (void)test_insertionIntoSecondObjectArray_OneWay_FirstObjectArrayNotChanged
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableArray *insertedObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int InsertedObjectsCount = arc4random_uniform(5) + 1;

    for (int i = 0; i < InsertedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount + InsertedObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [insertedObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertEqualObjects(_objectA.arrayA, initialObjects);
}

- (void)test_removalInSecondObjectArray_OneWay_FirstObjectArrayNotChanged
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int RemovedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < RemovedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] removeObjectsAtIndexes:indexes];

    XCTAssertEqualObjects(_objectA.arrayA, initialObjects);
}

- (void)test_replacementInSecondObjectArray_OneWay_FirstObjectArrayNotChanged
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableArray *replacingObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int ReplacedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < ReplacedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [replacingObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    XCTAssertEqualObjects(_objectA.arrayA, initialObjects);
}

- (void)test_insertionIntoSecondObjectArray_TwoWay_ChangesFirstObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableArray *insertedObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int InsertedObjectsCount = arc4random_uniform(5) + 1;

    for (int i = 0; i < InsertedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount + InsertedObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [insertedObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] insertObjects:insertedObjects atIndexes:indexes];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertEqualObjects(_objectA.arrayA, finalObjects);
}

- (void)test_removalInSecondObjectArray_TwoWay_ChangesFirstObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int RemovedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < RemovedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] removeObjectsAtIndexes:indexes];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects removeObjectsAtIndexes:indexes];

    XCTAssertEqualObjects(_objectA.arrayA, finalObjects);
}

- (void)test_replacementInSecondObjectArray_TwoWay_ChangesFirstObjectArrayWithUpdatedArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.arrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(arrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableArray *replacingObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int ReplacedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < ReplacedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [replacingObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.arrayA, _objectB.fineGrainedArrayB);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    NSMutableArray *finalObjects = [initialObjects mutableCopy];
    [finalObjects replaceObjectsAtIndexes:indexes withObjects:replacingObjects];
    
    XCTAssertEqualObjects(_objectA.arrayA, finalObjects);
}


#pragma mark - Fine Grained Updating Array Binding Test Methods

- (void)test_insertionIntoFirstObjectArray_InsertsObjectsIntoSecondObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableArray *insertedObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int InsertedObjectsCount = arc4random_uniform(5) + 1;

    for (int i = 0; i < InsertedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount + InsertedObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [insertedObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectB.insertedObjects);
    XCTAssertNil(_objectB.insertedIndexes);
    XCTAssertNil(_objectB.removedIndexes);
    XCTAssertNil(_objectB.replacingObjects);
    XCTAssertNil(_objectB.replacedIndexes);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertEqualObjects(_objectB.insertedObjects, insertedObjects);
    XCTAssertEqualObjects(_objectB.insertedIndexes, indexes);
    XCTAssertNil(_objectB.removedIndexes);
    XCTAssertNil(_objectB.replacingObjects);
    XCTAssertNil(_objectB.replacedIndexes);
}

- (void)test_removalInFirstObjectArray_RemovesObjectsFromSecondObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int RemovedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < RemovedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectB.insertedObjects);
    XCTAssertNil(_objectB.insertedIndexes);
    XCTAssertNil(_objectB.removedIndexes);
    XCTAssertNil(_objectB.replacingObjects);
    XCTAssertNil(_objectB.replacedIndexes);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] removeObjectsAtIndexes:indexes];

    XCTAssertNil(_objectB.insertedObjects);
    XCTAssertNil(_objectB.insertedIndexes);
    XCTAssertEqualObjects(_objectB.removedIndexes, indexes);
    XCTAssertNil(_objectB.replacingObjects);
    XCTAssertNil(_objectB.replacedIndexes);
}

- (void)test_replacementInFirstObjectArray_ReplacesObjectsInSecondObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    [_configuration setUpBinding];

    NSMutableArray *replacingObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int ReplacedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < ReplacedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [replacingObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectB.insertedObjects);
    XCTAssertNil(_objectB.insertedIndexes);
    XCTAssertNil(_objectB.removedIndexes);
    XCTAssertNil(_objectB.replacingObjects);
    XCTAssertNil(_objectB.replacedIndexes);

    [[_objectA mutableArrayValueForKey:@"fineGrainedArrayA"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    XCTAssertNil(_objectB.insertedObjects);
    XCTAssertNil(_objectB.insertedIndexes);
    XCTAssertNil(_objectB.removedIndexes);
    XCTAssertEqualObjects(_objectB.replacingObjects, replacingObjects);
    XCTAssertEqualObjects(_objectB.replacedIndexes, indexes);
}

- (void)test_insertionIntoSecondObjectArray_TwoWay_InsertsObjectsIntoFirstObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableArray *insertedObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int InsertedObjectsCount = arc4random_uniform(5) + 1;

    for (int i = 0; i < InsertedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount + InsertedObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [insertedObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectA.insertedObjects);
    XCTAssertNil(_objectA.insertedIndexes);
    XCTAssertNil(_objectA.removedIndexes);
    XCTAssertNil(_objectA.replacingObjects);
    XCTAssertNil(_objectA.replacedIndexes);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertEqualObjects(_objectA.insertedObjects, insertedObjects);
    XCTAssertEqualObjects(_objectA.insertedIndexes, indexes);
    XCTAssertNil(_objectA.removedIndexes);
    XCTAssertNil(_objectA.replacingObjects);
    XCTAssertNil(_objectA.replacedIndexes);
}

- (void)test_removalInSecondObjectArray_TwoWay_RemovesObjectsFromFirstObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int RemovedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < RemovedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectA.insertedObjects);
    XCTAssertNil(_objectA.insertedIndexes);
    XCTAssertNil(_objectA.removedIndexes);
    XCTAssertNil(_objectA.replacingObjects);
    XCTAssertNil(_objectA.replacedIndexes);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] removeObjectsAtIndexes:indexes];

    XCTAssertNil(_objectA.insertedObjects);
    XCTAssertNil(_objectA.insertedIndexes);
    XCTAssertEqualObjects(_objectA.removedIndexes, indexes);
    XCTAssertNil(_objectA.replacingObjects);
    XCTAssertNil(_objectA.replacedIndexes);
}

- (void)test_replacementInSecondObjectArray_TwoWay_ReplacesObjectsInFirstObjectArray
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _objectA.fineGrainedArrayA = initialObjects;

    _configuration.firstKeyPath = NSStringFromSelector(@selector(fineGrainedArrayA));
    _configuration.secondKeyPath = NSStringFromSelector(@selector(fineGrainedArrayB));
    _configuration.twoWay = YES;
    [_configuration setUpBinding];

    NSMutableArray *replacingObjects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    const int ObjectsCount = (int) initialObjects.count;
    const int ReplacedObjectsCount = arc4random_uniform(ObjectsCount - 1) + 1;

    for (int i = 0; i < ReplacedObjectsCount; i++) {

        NSUInteger idx;

        do {
            idx = arc4random_uniform(ObjectsCount);
        } while ([indexes containsIndex:idx]);

        [indexes addIndex:idx];
        [replacingObjects addObject:[NSObject new]];
    }

    XCTAssertEqualObjects(_objectA.fineGrainedArrayA, _objectB.fineGrainedArrayB);
    XCTAssertNil(_objectA.insertedObjects);
    XCTAssertNil(_objectA.insertedIndexes);
    XCTAssertNil(_objectA.removedIndexes);
    XCTAssertNil(_objectA.replacingObjects);
    XCTAssertNil(_objectA.replacedIndexes);

    [[_objectB mutableArrayValueForKey:@"fineGrainedArrayB"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    XCTAssertNil(_objectA.insertedObjects);
    XCTAssertNil(_objectA.insertedIndexes);
    XCTAssertNil(_objectA.removedIndexes);
    XCTAssertEqualObjects(_objectA.replacingObjects, replacingObjects);
    XCTAssertEqualObjects(_objectA.replacedIndexes, indexes);
}

- (void)test_unbind_RemovesMatchingBindings
{
    __auto_type object1 = [MFBBindingTestObjectA new];
    __auto_type object2 = [MFBBindingTestObjectB new];
    __auto_type object3 = [MFBBindingTestObjectA new];

    [object2 mfb_bind:NSStringFromSelector(@selector(propertyB))
             toObject:object1
          withKeyPath:NSStringFromSelector(@selector(propertyA))
              options:nil];

    [object2 mfb_bind:NSStringFromSelector(@selector(arrayB))
             toObject:object3
          withKeyPath:NSStringFromSelector(@selector(propertyA))
              options:nil];

    [object3 mfb_bind:NSStringFromSelector(@selector(arrayA))
             toObject:object2
          withKeyPath:NSStringFromSelector(@selector(propertyB))
              options:nil];

    [object2 mfb_unbind:NSStringFromSelector(@selector(propertyB))];

    XCTAssertEqual([object2 mfb_bindingsForKeyPath:NSStringFromSelector(@selector(propertyB))].count, 0);
    XCTAssertEqual([object2 mfb_bindingsForKeyPath:NSStringFromSelector(@selector(arrayB))].count, 1);
    XCTAssertEqual([object3 mfb_bindingsForKeyPath:NSStringFromSelector(@selector(arrayA))].count, 0);
}

/*
 1. B binds to A.propertyA and is being retained by that binding.
 2. B retains C through its property
 3. C binds to A.propertyA
 4. When A deallocates, unbinding of binding 1. causes deallocation of B and, consequently, deallocation of C,
 killing binding 3 and causing "array was mutated while being enumerated" exception in binding enumeration code.
 */
- (void)test_objectDealloc_MultipleBindingsCausingCascadeDeallocation_DoesNotThrow
{
    __auto_type objectA = [MFBBindingTestObjectA new];
    __auto_type objectB = [MFBBindingTestObjectB new];
    __auto_type objectC = [MFBBindingTestObjectA new];

    objectB.arrayB = @[ objectC ]; // make B retain C

    [objectC mfb_bind:NSStringFromSelector(@selector(propertyA))
             toObject:objectA
          withKeyPath:NSStringFromSelector(@selector(propertyA))
              options:nil];

    [objectB mfb_bind:NSStringFromSelector(@selector(propertyB))
             toObject:objectA
          withKeyPath:NSStringFromSelector(@selector(propertyA))
              options:@{
                  MFBRetainObserverBindingOption : @YES,
              }];

    objectC = nil;
    objectB = nil;
    // subgraph of B & C is now retained only by the binding between A & B
    objectA = nil;
}

@end
