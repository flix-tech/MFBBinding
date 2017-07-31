//
//  TestDataGenerators.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 01.08.2017.
//
//

#import "TestDataGenerators.h"

void EnumerateOptionalValues(void (^block)(id _Nullable value))
{
    id object = [NSObject new];

    block(object);
    block(nil); // From non-nil to nil
    block(object); // From nil to non-nil
}
