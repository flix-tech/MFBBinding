//
//  MFBActionBindingTests.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 31.07.2017.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <MFBBinding/MFBBinding.h>

@interface MFBActionBindingObservableTestObject : NSObject
@property (nonatomic) id property;
@end

@implementation MFBActionBindingObservableTestObject
@end

@interface MFBActionBindingTargetTestObject : NSObject
- (void)performAction;
@end

@implementation MFBActionBindingTargetTestObject

- (void)performAction
{
    [self doesNotRecognizeSelector:_cmd];
}

@end

@interface MFBActionBindingTests : XCTestCase

@end

@implementation MFBActionBindingTests {
    MFBActionBinding *_sut;
}

- (void)setUp 
{
    [super setUp];

    _sut = [MFBActionBinding new];
}


#pragma mark - Test Methods

#ifndef NS_BLOCK_ASSERTIONS
    #error Tests require assertions disabled
#else

- (void)test_BindingAssertion_NoBindingsForActionAndBindingAssertionEnabled_DoesNotThow
{
    MFBActionBindingObservableTestObject *object = [MFBActionBindingObservableTestObject new];

    XCTAssertNoThrow(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertNoThrow(MFBAssertActionToTriggerBinding(object, @selector(performAction)));

    object.bindingAssertionDisabled = YES;
    object.bindingAssertionDisabled = NO;

    XCTAssertNoThrow(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertNoThrow(MFBAssertActionToTriggerBinding(object, @selector(performAction)));
}

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionDisabled_DoesNotThow
{
    MFBActionBindingObservableTestObject *object = [MFBActionBindingObservableTestObject new];

    object.bindingAssertionDisabled = YES;

    XCTAssertNoThrow(MFBAssertTriggerToActionBinding(object, property));
    XCTAssertNoThrow(MFBAssertActionToTriggerBinding(object, @selector(performAction)));
}

#endif

@end
