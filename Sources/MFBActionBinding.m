//
//  MFBActionBinding.m
//  Pods
//
//  Created by Nickolay Tarbayev on 28.07.2017.
//
//

#import <objc/message.h>

#import "MFBActionBinding.h"
#import "MFBBindingInfo.h"
#import "MFBBinding.h"

static void *ObservableValueChange = &ObservableValueChange;

static NSString *const TriggeringBindingsGroup = @"TriggeringBindings";
static NSString *const ActionBindingsGroup = @"ActionBindings";

@interface MFBActionBinding () <MFBUnbindable>
@property (nonatomic) SEL actionSelector;
@end

@implementation MFBActionBinding {
    BOOL _isBound;
    BOOL _isUpdating;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self bind];
}

- (void)setObservable:(id)observable
{
    NSCParameterAssert(_keyPath != nil);
    NSCParameterAssert(_observable == nil);
    NSCParameterAssert(observable != nil);

    _observable = observable;

    [self registerIfValid];
}

- (void)setTarget:(id)target
{
    NSCParameterAssert(_actionSelector != NULL);
    NSCParameterAssert(_target == nil);
    NSCParameterAssert(target != nil);

    _target = target;

    [self registerIfValid];
}

- (NSString *)action
{
    return NSStringFromSelector(_actionSelector);
}

- (void)setAction:(NSString *)action
{
    _actionSelector = NSSelectorFromString(action);
}


#pragma mark - Private Methods

- (void)registerIfValid
{
    if (!_observable || !_target) {
        return;
    }

    NSCAssert([_target respondsToSelector:_actionSelector],
        @"Attempt to bind target %@ for unsupported action %@", _target, NSStringFromSelector(_actionSelector));

    [self registerForObservable];
    [self registerForTarget];
}

- (void)registerForObservable
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_observable];

    [bindingInfo addBinding:self forKey:_keyPath group:TriggeringBindingsGroup];
}

- (void)registerForTarget
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_target];

    NSString *key = NSStringFromSelector(_actionSelector);

    NSCAssert([bindingInfo bindingsForKey:key inGroup:ActionBindingsGroup].count == 0,
              @"Attempt to bind target %@ for action %@ which is already bound to another trigger. Unbind existing binding first.", _target, key);

    [bindingInfo addBinding:self forKey:key group:ActionBindingsGroup];
}

- (void)unregisterForObservable
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_observable];

    [bindingInfo removeBinding:self forKey:_keyPath group:TriggeringBindingsGroup];
}

- (void)unregisterForTarget
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:_target];

    [bindingInfo removeBinding:self forKey:NSStringFromSelector(_actionSelector) group:ActionBindingsGroup];
}

- (void)bind
{
    NSCParameterAssert(_observable != nil);
    NSCParameterAssert(_keyPath != nil);
    NSCParameterAssert(_target != nil);
    NSCParameterAssert(_actionSelector != NULL);

    if (_isBound) {
        return;
    }

    _isBound = YES;

    [_observable addObserver:self
                  forKeyPath:_keyPath
                     options:NSKeyValueObservingOptionNew
                     context:ObservableValueChange];
}

- (void)unbind
{
    [self unregisterForObservable];
    [self unregisterForTarget];

    if (!_isBound) {
        return;
    }

    _isBound = NO;

    [_observable removeObserver:self forKeyPath:_keyPath context:ObservableValueChange];
}


#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context
{

    if (context == ObservableValueChange && _target) {
        if (_isUpdating) {
            return;
        }
        _isUpdating = YES;

        void (*msgSend)(id, SEL) = (__typeof__(msgSend)) objc_msgSend;
        msgSend(_target, _actionSelector);

        _isUpdating = NO;
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end


#ifndef DEBUG
@interface NSObject (MFBActionBindingQueries)
- (id)mfb_bindingForAction:(SEL)action;
@end
#endif

@implementation NSObject (MFBActionBinding)

- (void)mfb_bindAction:(SEL)action toObject:(id)observableController withKeyPath:(NSString *)keyPath
{
    MFBActionBinding *binding = [MFBActionBinding new];

    binding.keyPath = keyPath;
    binding.actionSelector = action;

    // IBOutlet's should be set after IBDesignable's
    binding.observable = observableController;
    binding.target = self;

    [binding bind];
}

- (void)mfb_unbindAction:(SEL)action
{
    NSCParameterAssert(action != NULL);

    MFBActionBinding *binding = [self mfb_bindingForAction:action];

    [binding unbind];
}

@end

@implementation NSObject (MFBActionBindingQueries)

- (NSArray *)mfb_triggeringBindingsForKeyPath:(NSString *)keyPath
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:self];

    return [bindingInfo bindingsForKey:keyPath inGroup:TriggeringBindingsGroup];
}

- (id)mfb_bindingForAction:(SEL)action
{
    MFBBindingInfo *bindingInfo = [MFBBindingInfo bindingInfoForObject:self];

    return [bindingInfo bindingsForKey:NSStringFromSelector(action) inGroup:ActionBindingsGroup].firstObject;
}

@end
