//
//  MFBBindingInfo.m
//  Pods
//
//  Created by Nickolay Tarbayev on 28.07.2017.
//
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "MFBBinding.h"
#import "MFBBindingInfo.h"

@interface MFBBindingStore : NSObject
@end

@implementation MFBBindingStore {
    NSMutableDictionary<NSString *, NSMutableArray *> *_store;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        _store = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)addBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key
{
    NSCParameterAssert(binding != nil);
    NSCParameterAssert(key != nil);

    __auto_type list = _store[key];

    if (!list) {
        list = [NSMutableArray arrayWithObject:binding];
        _store[key] = list;
    } else {
        [list addObject:binding];
    }
}

- (void)removeBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key
{
    NSCParameterAssert(binding != nil);
    NSCParameterAssert(key != nil);

    __auto_type list = _store[key];

    [list removeObject:binding];
}

- (NSArray *)bindingsForKey:(NSString *)key
{
    NSCParameterAssert(key != nil);

    __auto_type list = _store[key];

    if (list.count == 0) {
        return @[];
    }

    return [list copy];
}

- (void)enumerateBindingsUsingBlock:(void (^)(id<MFBUnbindable>))block
{
    NSCParameterAssert(block != nil);

    for (NSMutableArray *list in _store.allValues) {
        for (id<MFBUnbindable> binding in [list copy]) {
            block(binding);
        }
    }
}

@end

@implementation MFBBindingInfo {
    __weak id _object;

    NSMutableDictionary<NSString *, MFBBindingStore *> *_stores;
}

static const void *BindingAssociationKey = &BindingAssociationKey;

+ (instancetype)bindingInfoForObject:(id)obj
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);

    if (!info) {
        info = [[self alloc] initWithObject:obj];

        objc_setAssociatedObject(obj, BindingAssociationKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return info;
}


#pragma mark - Private Methods

static void TweakDeallocForUnbindingIfNeeded(id obj)
{
    Class objClass = [obj class];

    static void *TweakedKey = &TweakedKey;

    if (objc_getAssociatedObject(objClass, TweakedKey)) {
        return;
    }

    SEL deallocSelector = sel_registerName("dealloc");

    __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;

    id newDealloc = ^(__unsafe_unretained id self) {

        MFBBindingInfo *info = objc_getAssociatedObject(self, BindingAssociationKey);
        [info _unbindAll];

        if (originalDealloc == NULL) {
            struct objc_super superInfo = {
                .receiver = self,
                .super_class = [objClass superclass]
            };

            void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
            msgSend(&superInfo, deallocSelector);
        } else {
            originalDealloc(self, deallocSelector);
        }
    };

    IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);

    if (!class_addMethod(objClass, deallocSelector, newDeallocIMP, "v@:")) {

        Method deallocMethod = class_getInstanceMethod(objClass, deallocSelector);

        originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
    }

    objc_setAssociatedObject(obj, TweakedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self) {

        TweakDeallocForUnbindingIfNeeded(object);

        _object = object;
        _stores = [NSMutableDictionary new];
    }
    return self;
}

- (void)addBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key group:(NSString *)group
{
    __auto_type store = _stores[group];

    if (!store) {
        store = [MFBBindingStore new];
        _stores[group] = store;
    }

    [store addBinding:binding forKey:key];
}

- (void)removeBinding:(id<MFBUnbindable>)binding forKey:(NSString *)key group:(NSString *)group
{
    __auto_type store = _stores[group];
    [store removeBinding:binding forKey:key];
}

- (NSArray *)bindingsForKey:(NSString *)key inGroup:(NSString *)group
{
    __auto_type store = _stores[group];
    return [store bindingsForKey:key] ?: @[];
}

- (void)_unbindAll
{
    for (MFBBindingStore *store in _stores.allValues) {
        [store enumerateBindingsUsingBlock:^(id<MFBUnbindable> binding) {
            [binding unbind];
        }];
    }
}

@end

