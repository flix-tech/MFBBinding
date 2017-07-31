//
//  MFBBindingTests_BlockAssertions.m
//  MFBBindingTests_BlockAssertions
//
//  Created by Nickolay Tarbayev on 31.07.2017.
//
//

#import <XCTest/XCTest.h>
#import <MFBBinding/MFBBinding.h>

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

@interface MFBBindingTests : XCTestCase

@end

@implementation MFBBindingTests

- (void)setUp {
    [super setUp];
}

#ifndef NS_BLOCK_ASSERTIONS
    #error Tests require assertions disabled
#else

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionEnabled_DoesNotThow
{

    MFBBindingTestObjectA *object = [MFBBindingTestObjectA new];

    XCTAssertNoThrow(MFBAssertSetterBinding(object, propertyA));
    XCTAssertNoThrow(MFBAssertGetterBinding(object, propertyA));

    object.bindingAssertionDisabled = YES;
    object.bindingAssertionDisabled = NO;

    XCTAssertNoThrow(MFBAssertSetterBinding(object, propertyA));
    XCTAssertNoThrow(MFBAssertGetterBinding(object, propertyA));
}

- (void)test_BindingAssertion_NoBindingsForKeyPathAndBindingAssertionDisabled_DoesNotThow
{
    MFBBindingTestObjectA *object = [MFBBindingTestObjectA new];

    object.bindingAssertionDisabled = YES;

    XCTAssertNoThrow(MFBAssertSetterBinding(object, propertyA));
    XCTAssertNoThrow(MFBAssertGetterBinding(object, propertyA));
}

#endif

@end
