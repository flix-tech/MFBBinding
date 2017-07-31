//
//  MFBActionBindingTests.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 28.07.2017.
//
//

#import <XCTest/XCTest.h>
#import <MFBBinding/MFBBinding.h>

#import "TestDataGenerators.h"

@interface MFBActionBindingObservableTestObject : NSObject
@property (nonatomic) id property;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, copy) NSArray *fineGrainedArray;
@end

@implementation MFBActionBindingObservableTestObject {
    NSMutableArray *_mutableArray;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableArray = [NSMutableArray new];
    }
    return self;
}

- (NSArray *)fineGrainedArray
{
    return _mutableArray;
}

- (void)setFineGrainedArray:(NSArray *)array
{
    _mutableArray.array = array;
}

- (void)insertFineGrainedArray:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_mutableArray insertObjects:array atIndexes:indexes];
}

- (void)removeFineGrainedArrayAtIndexes:(NSIndexSet *)indexes
{
    [_mutableArray removeObjectsAtIndexes:indexes];
}

- (void)replaceFineGrainedArrayAtIndexes:(NSIndexSet *)indexes withFineGrainedArray:(NSArray *)array
{
    [_mutableArray replaceObjectsAtIndexes:indexes withObjects:array];
}

@end

@interface MFBActionBindingTargetTestObject : NSObject

- (void)performAction;

- (void)expectPerformAction;

- (BOOL)verify;

@end

@implementation MFBActionBindingTargetTestObject {
    BOOL _performActionExpected;
    BOOL _performActionInvoked;
}

- (void)performAction
{
    if (!_performActionExpected) {
        [self doesNotRecognizeSelector:_cmd];
    }

    _performActionInvoked = YES;
}

- (void)expectPerformAction
{
    _performActionExpected = YES;
}

- (BOOL)verify
{
    return _performActionInvoked;
}

@end

@interface MFBActionBindingTestConfiguration : NSObject

@property (nonatomic, unsafe_unretained) id observable;
@property (nonatomic, copy) NSString *keyPath;

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic) SEL action;

- (void)setUpBinding;
- (void)registerBinding;

@end

@implementation MFBActionBindingTestConfiguration

- (void)setUpBinding
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)registerBinding
{
    [self doesNotRecognizeSelector:_cmd];
}

@end

@interface MFBIBActionBindingTestConfiguration : MFBActionBindingTestConfiguration
@end

@implementation MFBIBActionBindingTestConfiguration

- (void)setUpBinding
{
    MFBActionBinding *binding = [self loadIBBinding];

    [binding awakeFromNib];
}

- (void)registerBinding
{
    [self loadIBBinding];
}

- (MFBActionBinding *)loadIBBinding
{
    MFBActionBinding *binding = [MFBActionBinding new];

    binding.keyPath = self.keyPath;
    binding.action = NSStringFromSelector(self.action);

    // IBOutlet's should be set after IBDesignable's
    binding.observable = self.observable;
    binding.target = self.target;

    return binding;
}

@end

@interface MFBInCodeActionBindingTestConfiguration : MFBActionBindingTestConfiguration
@end

@implementation MFBInCodeActionBindingTestConfiguration

- (void)setUpBinding
{
    [self.target mfb_bindAction:self.action
                       toObject:self.observable
                    withKeyPath:self.keyPath];
}

- (void)registerBinding
{
    [self setUpBinding];
}

@end

#pragma mark -

@interface MFBActionBindingTests : XCTestCase

@end

@implementation MFBActionBindingTests {
    MFBActionBindingObservableTestObject *_observable;
    MFBActionBindingTargetTestObject *_target;

    MFBActionBindingTestConfiguration *_configuration;
}

- (void)invokeTest
{
    NSArray *configurationClasses = @[
        [MFBIBActionBindingTestConfiguration class],
        [MFBInCodeActionBindingTestConfiguration class]
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

    _configuration.observable =
    _observable = [MFBActionBindingObservableTestObject new];

    _configuration.keyPath = NSStringFromSelector(@selector(property));

    _configuration.target = _target = [MFBActionBindingTargetTestObject new];

    _configuration.action = @selector(performAction);
}


#pragma mark - Test Methods

#pragma mark - Value Binding Test Methods

- (void)test_observablePropertyChange_TriggersActionOnTarget
{
    [_configuration setUpBinding];

    EnumerateOptionalValues(^(id value) {

        [_target expectPerformAction];

        _observable.property = value;

        XCTAssertTrue([_target verify]);
    });
}

- (void)test_observablePropertyChange_TargetUnbound_DoesNothing
{
    [_configuration setUpBinding];

    [_target mfb_unbindAction:@selector(performAction)];

    EnumerateOptionalValues(^(id value) {
        _observable.property = value;
    });
}

- (void)test_insertionIntoObservableArray_TriggersActionOnTarget
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _observable.fineGrainedArray = initialObjects;

    _configuration.keyPath = NSStringFromSelector(@selector(fineGrainedArray));
    _configuration.action = @selector(performAction);
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

    [_target expectPerformAction];

    [[_observable mutableArrayValueForKey:@"fineGrainedArray"] insertObjects:insertedObjects atIndexes:indexes];

    XCTAssertTrue([_target verify]);
}

- (void)test_removalFromObservableArray_TriggersActionOnTarget
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _observable.fineGrainedArray = initialObjects;

    _configuration.keyPath = NSStringFromSelector(@selector(fineGrainedArray));
    _configuration.action = @selector(performAction);
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

    [_target expectPerformAction];

    [[_observable mutableArrayValueForKey:@"fineGrainedArray"] removeObjectsAtIndexes:indexes];

    XCTAssertTrue([_target verify]);
}

- (void)test_replacementInObservableArray_TriggersActionOnTarget
{
    NSArray *initialObjects = @[ [NSObject new], [NSObject new], [NSObject new] ];

    _observable.fineGrainedArray = initialObjects;

    _configuration.keyPath = NSStringFromSelector(@selector(fineGrainedArray));
    _configuration.action = @selector(performAction);
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

    [_target expectPerformAction];

    [[_observable mutableArrayValueForKey:@"fineGrainedArray"] replaceObjectsAtIndexes:indexes withObjects:replacingObjects];

    XCTAssertTrue([_target verify]);
}

#pragma mark - Memory Management and Query Test Methods

#ifdef DEBUG

- (void)test_observableDeallocation_BindingDeallocated
{
    [_configuration setUpBinding];

    id binding;

    @autoreleasepool {
        binding = [_observable mfb_triggeringBindingsForKeyPath:NSStringFromSelector(@selector(property))];
    }

    __weak id WeakBinding = binding;
    __weak id WeakObjA = _observable;

    binding = nil;
    _observable = nil;

    XCTAssertNil(WeakObjA);
    XCTAssertNil(WeakBinding);
}

- (void)test_targetDeallocation_BindingDeallocated
{
    id binding;

    @autoreleasepool {
        [_configuration setUpBinding];
        binding = [_target mfb_bindingForAction:@selector(performAction)];
    }

    __weak id WeakBinding = binding;
    __weak id WeakObjB = _target;

    binding = nil;
    _target = nil;

    XCTAssertNil(WeakObjB);
    XCTAssertNil(WeakBinding);

    _observable.property = @"Some";
}

- (void)test_observableBindingStaysAliveIfBothObjectsAreAlive
{
    [_configuration setUpBinding];

    id binding;

    @autoreleasepool {
        binding = [_observable mfb_triggeringBindingsForKeyPath:NSStringFromSelector(@selector(property))][0];
    }
    XCTAssertNotNil(binding);

    __weak id WeakBinding = binding;

    binding = nil;

    XCTAssertNotNil(WeakBinding);
}

- (void)test_targetBindingStaysAliveIfBothObjectsAreAlive
{
    [_configuration setUpBinding];

    id binding;

    @autoreleasepool {
        binding = [_target mfb_bindingForAction:@selector(performAction)];
    }

    __weak id WeakBinding = binding;

    binding = nil;

    XCTAssertNotNil(WeakBinding);
}

- (void)test_sharesSameBindingObjectForObservableAndTarget
{
    [_configuration registerBinding];

    // Binding should be returned for an object even if awakeFromNib has not been yet called on the binding.
    id observableBinding = [_observable mfb_triggeringBindingsForKeyPath:NSStringFromSelector(@selector(property))][0];
    id targetBinding = [_target mfb_bindingForAction:@selector(performAction)];

    XCTAssertNotNil(observableBinding);
    XCTAssertNotNil(targetBinding);
    XCTAssertEqualObjects(observableBinding, targetBinding);
}


#pragma mark - Unbinding Test Methods

- (void)test_unbindAction_OneToManyBinding_RemovesMatchingBinding
{
    [_configuration setUpBinding];

    __auto_type target2 = [MFBActionBindingTargetTestObject new];

    _configuration.target = target2;
    [_configuration setUpBinding];

    id target2Binding = [target2 mfb_bindingForAction:@selector(performAction)];

    [_target mfb_unbindAction:@selector(performAction)];
    XCTAssertNil([_target mfb_bindingForAction:@selector(performAction)]);
    XCTAssertEqualObjects([_observable mfb_triggeringBindingsForKeyPath:NSStringFromSelector(@selector(property))], @[ target2Binding ]);

    [target2 mfb_unbindAction:@selector(performAction)];
    XCTAssertNil([target2 mfb_bindingForAction:@selector(performAction)]);
    XCTAssertEqualObjects([_observable mfb_triggeringBindingsForKeyPath:NSStringFromSelector(@selector(property))], @[]);
}


#pragma mark - Binding Assertions Test Methods

#ifdef NS_BLOCK_ASSERTIONS
    #error Tests require assertions enabled
#else

- (void)test_BindingAssertion_NoBindingsForActionAndBindingAssertionEnabled_Thows
{
    MFBActionBindingObservableTestObject *object = [MFBActionBindingObservableTestObject new];

    XCTAssertThrows(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertThrows(MFBAssertActionToTriggerBinding(object, @selector(performAction)));

    object.bindingAssertionDisabled = YES;
    object.bindingAssertionDisabled = NO;

    XCTAssertThrows(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertThrows(MFBAssertActionToTriggerBinding(object, @selector(performAction)));
}

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionDisabled_DoesNotThow
{
    MFBActionBindingObservableTestObject *object = [MFBActionBindingObservableTestObject new];

    object.bindingAssertionDisabled = YES;

    XCTAssertNoThrow(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertNoThrow(MFBAssertActionToTriggerBinding(object, @selector(performAction)));
}

#endif // #ifdef NS_BLOCK_ASSERTIONS

#endif // #ifdef DEBUG

@end
