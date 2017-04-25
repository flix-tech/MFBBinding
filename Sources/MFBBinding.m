//
//  MFBBinding.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 01.08.16.
//
//

#import "MFBBinding.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface MFBBinding ()
- (void)unbind;
@end

@interface MFBBindingStore : NSObject

- (void)addBinding:(MFBBinding *)binding forKeyPath:(NSString *)keyPath;
- (void)removeBinding:(MFBBinding *)binding forKeyPath:(NSString *)keyPath;
- (NSArray<MFBBinding *> *)bindingsForKeyPath:(NSString *)keyPath;

- (void)enumerateBindingsUsingBlock:(void (^)(MFBBinding *binding))block;

@end

@implementation MFBBindingStore {
    NSMutableDictionary<NSString *, NSMutableArray<MFBBinding *> *> *_store;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        _store = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)addBinding:(MFBBinding *)binding forKeyPath:(NSString *)keyPath
{
    NSCParameterAssert(binding != nil);
    NSCParameterAssert(keyPath != nil);

    __auto_type list = _store[keyPath];

    if (!list) {
        list = [NSMutableArray arrayWithObject:binding];
        _store[keyPath] = list;
    } else {
        [list addObject:binding];
    }
}

- (void)removeBinding:(MFBBinding *)binding forKeyPath:(NSString *)keyPath
{
    NSCParameterAssert(binding != nil);
    NSCParameterAssert(keyPath != nil);

    __auto_type list = _store[keyPath];

    [list removeObject:binding];
}

- (NSArray<MFBBinding *> *)bindingsForKeyPath:(NSString *)keyPath
{
    NSCParameterAssert(keyPath != nil);

    __auto_type list = _store[keyPath];

    if (list.count == 0) {
        return @[];
    }

    return [list copy];
}

- (void)enumerateBindingsUsingBlock:(void (^)(MFBBinding *))block
{
    NSCParameterAssert(block != nil);

    [_store enumerateKeysAndObjectsUsingBlock:^(NSString *_, NSMutableArray<MFBBinding *> *list, BOOL *__) {
        for (MFBBinding *binding in [list copy]) {
            block(binding);
        }
    }];
}

@end

@interface MFBBindingInfo : NSObject
+ (void)registerBinding:(MFBBinding *)binding forObject:(id)obj;
+ (void)unregisterBinding:(MFBBinding *)binding forObject:(id)obj;
+ (NSArray<MFBBinding *> *)bindingsForObject:(id)obj keyPath:(NSString *)keyPath;
@end

@implementation MFBBindingInfo {
    __weak id _object;

    MFBBindingStore *_setterBindings;
    MFBBindingStore *_getterBindings;
}

static const void *BindingAssociationKey = &BindingAssociationKey;

+ (void)registerBinding:(MFBBinding *)binding forObject:(id)obj
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);

    if (!info) {
        info = [[self alloc] initWithObject:obj];

        objc_setAssociatedObject(obj, BindingAssociationKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [info _registerBinding:binding];
}

+ (void)unregisterBinding:(MFBBinding *)binding forObject:(id)obj
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);
    [info _unregisterBinding:binding];
}

+ (NSArray<MFBBinding *> *)bindingsForObject:(id)obj keyPath:(NSString *)keyPath
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);
    return [info _bindingsForKeyPath:keyPath];
}

+ (NSArray<MFBBinding *> *)getterBindingsForObject:(id)obj keyPath:(NSString *)keyPath
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);
    return [info _getterBindingsForKeyPath:keyPath];
}

+ (NSArray<MFBBinding *> *)setterBindingsForObject:(id)obj keyPath:(NSString *)keyPath
{
    MFBBindingInfo *info = objc_getAssociatedObject(obj, BindingAssociationKey);
    return [info _setterBindingsForKeyPath:keyPath];
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
        _setterBindings = [MFBBindingStore new];
        _getterBindings = [MFBBindingStore new];
    }
    return self;
}

- (void)_registerBinding:(MFBBinding *)binding
{
    if (binding.secondObject == _object) {
        [_setterBindings addBinding:binding forKeyPath:binding.secondKeyPath];
    } else if (binding.firstObject == _object) {
        [_setterBindings addBinding:binding forKeyPath:binding.firstKeyPath];
    }

    if (binding.firstObject == _object) {
        [_getterBindings addBinding:binding forKeyPath:binding.firstKeyPath];
    } else if (binding.secondObject == _object) {
        [_getterBindings addBinding:binding forKeyPath:binding.secondKeyPath];
    }
}

- (void)_unregisterBinding:(MFBBinding *)binding
{
    [_setterBindings removeBinding:binding forKeyPath:binding.secondKeyPath];
    [_setterBindings removeBinding:binding forKeyPath:binding.firstKeyPath];

    [_getterBindings removeBinding:binding forKeyPath:binding.firstKeyPath];
    [_getterBindings removeBinding:binding forKeyPath:binding.secondKeyPath];
}

- (NSArray<MFBBinding *> *)_bindingsForKeyPath:(NSString *)keyPath
{
    __auto_type setterBindings = [self _setterBindingsForKeyPath:keyPath];
    __auto_type getterBindings = [self _getterBindingsForKeyPath:keyPath];

    __auto_type uniqueBindings = [NSMutableSet<MFBBinding *> setWithArray:setterBindings];
    [uniqueBindings addObjectsFromArray:getterBindings];

    return uniqueBindings.allObjects;
}

- (NSArray<MFBBinding *> *)_getterBindingsForKeyPath:(NSString *)keyPath
{
    __auto_type list = [_getterBindings bindingsForKeyPath:keyPath];

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(MFBBinding *evaluatedObject, NSDictionary<NSString *,id> *_) {
        if (evaluatedObject.secondObject == _object) {
            return evaluatedObject.twoWay;
        }

        return YES;
    }];

    return [list filteredArrayUsingPredicate:predicate];
}

- (NSArray<MFBBinding *> *)_setterBindingsForKeyPath:(NSString *)keyPath
{
    __auto_type list = [_setterBindings bindingsForKeyPath:keyPath];

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(MFBBinding *evaluatedObject, NSDictionary<NSString *,id> *_) {
        if (evaluatedObject.firstObject == _object) {
            return evaluatedObject.twoWay;
        }

        return YES;
    }];

    return [list filteredArrayUsingPredicate:predicate];
}

- (void)_unbindAll
{
    __auto_type iteration = ^(MFBBinding *binding) {
        [binding unbind];
    };

    [_getterBindings enumerateBindingsUsingBlock:iteration];
    [_setterBindings enumerateBindingsUsingBlock:iteration];
}

@end


static void *FirstToSecondKey = &FirstToSecondKey;
static void *SecondToFirstKey = &SecondToFirstKey;

@implementation MFBBinding {
    struct {
        unsigned int binded:1;
        unsigned int updating:1;
    } _flags;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self bind];
}

- (void)setFirstObject:(id)firstObject
{
    NSCParameterAssert(firstObject != nil);

    if (_firstObject) {
        [MFBBindingInfo unregisterBinding:self forObject:_firstObject];
    }

    _firstObject = firstObject;

    [self registerIfValid];
}

- (void)setFirstKeyPath:(NSString *)firstKeyPath
{
    NSCParameterAssert(firstKeyPath != nil);

    _firstKeyPath = [firstKeyPath copy];

    [self registerIfValid];
}

- (void)setSecondObject:(id)secondObject
{
    NSCParameterAssert(secondObject != nil);

    if (_secondObject) {
        [MFBBindingInfo unregisterBinding:self forObject:_secondObject];
    }

    _secondObject = secondObject;

    [self registerIfValid];
}

- (void)setSecondKeyPath:(NSString *)secondKeyPath
{
    NSCParameterAssert(secondKeyPath != nil);

    _secondKeyPath = [secondKeyPath copy];

    [self registerIfValid];
}

- (NSValueTransformer *)valueTransformer
{
    if (_valueTransformer) {
        return _valueTransformer;
    }

    if (_valueTransformerName) {
        return [NSValueTransformer valueTransformerForName:_valueTransformerName];
    }

    return nil;
}


#pragma mark - Private Methods

- (void)registerIfValid
{
    if (!_firstObject || !_firstKeyPath || !_secondObject || !_secondKeyPath) {
        return;
    }

    [MFBBindingInfo registerBinding:self forObject:_firstObject];
    [MFBBindingInfo registerBinding:self forObject:_secondObject];
}

- (void)bind
{
    NSCParameterAssert(_firstObject != nil);
    NSCParameterAssert(_firstKeyPath != nil);
    NSCParameterAssert(_secondObject != nil);
    NSCParameterAssert(_secondKeyPath != nil);

    NSCParameterAssert(!(_twoWay && self.valueTransformer) || [self.valueTransformer.class allowsReverseTransformation]);
    
    if (_flags.binded) {
        return;
    }

    _flags.binded = YES;

    [_firstObject addObserver:self
                   forKeyPath:_firstKeyPath
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:FirstToSecondKey];

    if ([_firstObject isKindOfClass:[UIControl class]]) {
        [_firstObject addTarget:self
                         action:@selector(controlChanged:)
               forControlEvents:UIControlEventValueChanged | UIControlEventEditingChanged];
    }

    if (_retainsSecondObject) {
        objc_setAssociatedObject(self, @selector(secondObject), _secondObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (_twoWay) {
        [_secondObject addObserver:self
                        forKeyPath:_secondKeyPath
                           options:NSKeyValueObservingOptionNew
                           context:SecondToFirstKey];

        if ([_secondObject isKindOfClass:[UIControl class]]) {
            [_secondObject addTarget:self
                              action:@selector(controlChanged:)
                    forControlEvents:UIControlEventValueChanged | UIControlEventEditingChanged];
        }
    }
}

- (void)unbind
{
    [MFBBindingInfo unregisterBinding:self forObject:_firstObject];
    [MFBBindingInfo unregisterBinding:self forObject:_secondObject];

    if (!_flags.binded) {
        return;
    }

    _flags.binded = NO;

    [_firstObject removeObserver:self forKeyPath:_firstKeyPath context:FirstToSecondKey];

    if ([_firstObject isKindOfClass:[UIControl class]]) {
        [_firstObject removeTarget:self
                            action:@selector(controlChanged:)
                  forControlEvents:UIControlEventValueChanged | UIControlEventEditingChanged];
    }

    if (_twoWay) {
        [_secondObject removeObserver:self forKeyPath:_secondKeyPath context:SecondToFirstKey];

        if ([_secondObject isKindOfClass:[UIControl class]]) {
            [_secondObject removeTarget:self
                                 action:@selector(controlChanged:)
                       forControlEvents:UIControlEventValueChanged | UIControlEventEditingChanged];
        }
    }
}

- (void)updateObject:(id)object
          forKeyPath:(NSString *)keyPath
              change:(NSDictionary<NSString *, id> *)change
         transformer:(id(^)(NSValueTransformer *, id))transformer
{
    if (_flags.updating) {
        return;
    }

    id newValue = change[NSKeyValueChangeNewKey];

    if (newValue == [NSNull null]) {
        newValue = nil;
    }

    NSValueTransformer *valueTransformer = self.valueTransformer;

    if (valueTransformer) {
        newValue = transformer(valueTransformer, newValue);
    }

    _flags.updating = YES;

    switch ([change[NSKeyValueChangeKindKey] unsignedIntegerValue]) {
        case NSKeyValueChangeSetting:
            [object setValue:newValue forKeyPath:keyPath];
            break;
        case NSKeyValueChangeInsertion: {
            NSMutableArray *proxyArray = [object mutableArrayValueForKeyPath:keyPath];
            NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
            [proxyArray insertObjects:newValue atIndexes:indexes];
            break;
        }
        case NSKeyValueChangeRemoval: {
            NSMutableArray *proxyArray = [object mutableArrayValueForKeyPath:keyPath];
            NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
            [proxyArray removeObjectsAtIndexes:indexes];
            break;
        }
        case NSKeyValueChangeReplacement: {
            NSMutableArray *proxyArray = [object mutableArrayValueForKeyPath:keyPath];
            NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
            [proxyArray replaceObjectsAtIndexes:indexes withObjects:newValue];
            break;
        }
    }

    _flags.updating = NO;
}

static __auto_type ForwardTransformer = ^(NSValueTransformer *valueTransformer, id value) {
    return [valueTransformer transformedValue:value];
};

static __auto_type ReverseTransformer = ^(NSValueTransformer *valueTransformer, id value) {
    return [valueTransformer reverseTransformedValue:value];
};


#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context
{

    if (context == FirstToSecondKey) {
        [self updateObject:_secondObject forKeyPath:_secondKeyPath change:change transformer:ForwardTransformer];
        return;
    }

    if (context == SecondToFirstKey) {
        [self updateObject:_firstObject forKeyPath:_firstKeyPath change:change transformer:ReverseTransformer];
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - Actions

- (void)controlChanged:(id)sender
{
    NSString *key = sender == _firstObject ? _firstKeyPath : _secondKeyPath;

    [sender willChangeValueForKey:key];
    [sender didChangeValueForKey:key];
}

@end

NSString *const MFBTwoWayBindingOption = @"MFBTwoWayBindingOption";
NSString *const MFBRetainObserverBindingOption = @"MFBRetainObserverBindingOption";
NSString *const MFBValueTransformerBindingOption = @"MFBValueTransformerBindingOption";
NSString *const MFBValueTransformerNameBindingOption = @"MFBValueTransformerNameBindingOption";

@implementation NSObject (MFBBinding)

- (void)mfb_bind:(NSString *)binding toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary<NSString *,id> *)options
{
    MFBBinding *bindingController = [MFBBinding new];

    bindingController.firstObject = observableController;
    bindingController.firstKeyPath = keyPath;

    bindingController.secondObject = self;
    bindingController.secondKeyPath = binding;

    bindingController.twoWay = [options[MFBTwoWayBindingOption] boolValue];
    bindingController.retainsSecondObject = [options[MFBRetainObserverBindingOption] boolValue];

    bindingController.valueTransformerName = options[MFBValueTransformerNameBindingOption];
    bindingController.valueTransformer = options[MFBValueTransformerBindingOption];

    [bindingController bind];
}

- (void)mfb_unbindAll:(NSString *)binding
{
    NSCParameterAssert(binding != nil);

    __auto_type bindings = [self mfb_bindingsForKeyPath:binding];

    [bindings makeObjectsPerformSelector:@selector(unbind)];
}

- (NSArray<MFBBinding *> *)mfb_bindingsForKeyPath:(NSString *)keyPath
{
    return [MFBBindingInfo bindingsForObject:self keyPath:keyPath];
}

- (NSArray<MFBBinding *> *)mfb_getterBindingsForKeyPath:(NSString *)keyPath
{
    return [MFBBindingInfo getterBindingsForObject:self keyPath:keyPath];
}

- (NSArray<MFBBinding *> *)mfb_setterBindingsForKeyPath:(NSString *)keyPath
{
    return [MFBBindingInfo setterBindingsForObject:self keyPath:keyPath];
}

- (BOOL)bindingAssertionDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBindingAssertionDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(bindingAssertionDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN);
}

@end
