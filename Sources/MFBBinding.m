//
//  MFBBinding.m
//  MFBBinding
//
//  Created by Nickolay Tarbayev on 01.08.16.
//
//

#import <objc/runtime.h>

#import "MFBBinding.h"
#import "MFBBindingInfo.h"

static void *FirstToSecondKey = &FirstToSecondKey;
static void *SecondToFirstKey = &SecondToFirstKey;

static NSString *const GetterBindingsGroup = @"GetterBindings";
static NSString *const SetterBindingsGroup = @"SetterBindings";

@interface MFBBinding () <MFBUnbindable>
@end

@implementation MFBBinding {
    BOOL _isBound;
    BOOL _isUpdating;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self bind];
}

- (void)setFirstObject:(id)firstObject
{
    NSCParameterAssert(_firstKeyPath != nil);
    NSCParameterAssert(_firstObject == nil);
    NSCParameterAssert(firstObject != nil);

    _firstObject = firstObject;

    [self registerIfValid];
}

- (void)setSecondObject:(id)secondObject
{
    NSCParameterAssert(_secondKeyPath != nil);
    NSCParameterAssert(_secondObject == nil);
    NSCParameterAssert(secondObject != nil);

    _secondObject = secondObject;

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
    if (!_firstObject || !_secondObject) {
        return;
    }

    [self registerForFirstObject];
    [self registerForSecondObject];
}

- (void)registerForFirstObject
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_firstObject];

    [bindingInfo addBinding:self forKey:_firstKeyPath group:GetterBindingsGroup];

    if (_twoWay) {
        [bindingInfo addBinding:self forKey:_firstKeyPath group:SetterBindingsGroup];
    }
}

- (void)registerForSecondObject
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_secondObject];

    [bindingInfo addBinding:self forKey:_secondKeyPath group:SetterBindingsGroup];

    if (_twoWay) {
        [bindingInfo addBinding:self forKey:_secondKeyPath group:GetterBindingsGroup];
    }
}

- (void)unregisterForObject:(id)obj
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:obj];

    [bindingInfo removeBinding:self forKey:_secondKeyPath group:SetterBindingsGroup];
    [bindingInfo removeBinding:self forKey:_firstKeyPath group:SetterBindingsGroup];

    [bindingInfo removeBinding:self forKey:_firstKeyPath group:GetterBindingsGroup];
    [bindingInfo removeBinding:self forKey:_secondKeyPath group:GetterBindingsGroup];
}

- (void)bind
{
    NSCParameterAssert(_firstObject != nil);
    NSCParameterAssert(_firstKeyPath != nil);
    NSCParameterAssert(_secondObject != nil);
    NSCParameterAssert(_secondKeyPath != nil);

    NSCParameterAssert(!(_twoWay && self.valueTransformer) || [self.valueTransformer.class allowsReverseTransformation]);
    
    if (_isBound) {
        return;
    }

    _isBound = YES;

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
    [self unregisterForObject:_firstObject];
    [self unregisterForObject:_secondObject];

    if (!_isBound) {
        return;
    }

    _isBound = NO;

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
    if (_isUpdating) {
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

    _isUpdating = YES;

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

    _isUpdating = NO;
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

    bindingController.firstKeyPath = keyPath;
    bindingController.secondKeyPath = binding;
    bindingController.twoWay = [options[MFBTwoWayBindingOption] boolValue];
    bindingController.retainsSecondObject = [options[MFBRetainObserverBindingOption] boolValue];
    bindingController.valueTransformerName = options[MFBValueTransformerNameBindingOption];

    bindingController.valueTransformer = options[MFBValueTransformerBindingOption];

    // IBOutlet's should be set after IBDesignable's
    bindingController.firstObject = observableController;
    bindingController.secondObject = self;

    [bindingController bind];
}

- (void)mfb_unbind:(NSString *)binding
{
    NSCParameterAssert(binding != nil);

    __auto_type bindings = [self mfb_setterBindingsForKeyPath:binding];

    [bindings makeObjectsPerformSelector:@selector(unbind)];
}

- (NSArray *)mfb_getterBindingsForKeyPath:(NSString *)keyPath
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:self];

    return [bindingInfo bindingsForKey:keyPath inGroup:GetterBindingsGroup];
}

- (NSArray *)mfb_setterBindingsForKeyPath:(NSString *)keyPath
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:self];

    return [bindingInfo bindingsForKey:keyPath inGroup:SetterBindingsGroup];
}

@end
