//
//  MFBBindingInfo.h
//  Pods
//
//  Created by Nickolay Tarbayev on 28.07.2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MFBUnbindable
- (void)unbind;
@end

@interface MFBBindingInfo : NSObject

+ (instancetype)bindingInfoForObject:(id)obj;

- (void)addBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key group:(NSString *)group;
- (void)removeBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key group:(NSString *)group;

- (NSArray *)bindingsForKey:(NSString *)key inGroup:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
