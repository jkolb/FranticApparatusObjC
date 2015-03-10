//
// FAPromise.m
// FranticApparatusObjC
//
// Copyright (c) 2015 Justin Kolb - http://franticapparatus.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "FAPromise.h"
#import "FADispatchQueue.h"
#import "FAError.h"
#import "FAMacro.h"


typedef NS_ENUM(NSUInteger, FAPromiseState) {
    FAPromiseStatePending,
    FAPromiseStateFulfilled,
    FAPromiseStateRejected,
};

typedef void (^FAResolveBlock)(id);


@interface FAPromise () <FASynchronizable>

@property (nonatomic, readonly, strong) id<FADispatchQueue> synchronizationQueue;
@property (nonatomic) FAPromiseState state;
@property (nonatomic, strong) id result;
@property (nonatomic, readonly, strong) FAPromise *parent;
@property (nonatomic, strong) NSMutableArray *onFulfilled;
@property (nonatomic, strong) NSMutableArray *onRejected;

@end


@implementation FAPromise

- (instancetype)initWithResolver:(void (^)(FAFulfillBlock fulfill, FARejectBlock reject, FAIsCancelledBlock isCancelled))resolver {
    self = [super init];
    if (self == nil) return nil;
    _synchronizationQueue = [FAGCDQueue serial:@"net.franticapparatus.Promise"];
    _onFulfilled = [NSMutableArray arrayWithCapacity:1];
    _onRejected = [NSMutableArray arrayWithCapacity:1];
    FAWeakSelf;
    FAFulfillBlock weakFulfill = ^(id value) {
        FAStrongSelfOrReturn;
        [strongSelf resolve:value];
    };
    FARejectBlock weakReject = ^(NSError *reason) {
        FAStrongSelfOrReturn;
        [strongSelf resolve:reason];
    };
    FAIsCancelledBlock isCancelled = ^BOOL() {
        FAStrongSelfOrReturn YES;
        return NO;
    };
    resolver([weakFulfill copy], [weakReject copy], [isCancelled copy]);
    return self;
}

- (instancetype)initWithParent:(FAPromise *)parent synchronizationQueue:(id<FADispatchQueue>)queue resolver:(void (^)(id))resolver {
    self = [super init];
    if (self == nil) return nil;
    _parent = parent;
    _synchronizationQueue = queue;
    _onFulfilled = [NSMutableArray arrayWithCapacity:1];
    _onRejected = [NSMutableArray arrayWithCapacity:1];
    FAWeakSelf;
    FAResolveBlock weakResolve = ^(id result) {
        FAStrongSelfOrReturn;
        [strongSelf resolve:result];
    };
    resolver([weakResolve copy]);
    return self;
}

- (void)resolve:(id)result {
    FASynchronizeWrite(self, ^(FATypeOfSelf promise) {
        [promise transition:result];
    });
}

- (void)transition:(id)result {
    switch (self.state) {
        case FAPromiseStatePending:
            if ([result isKindOfClass:[FAPromise class]]) {
                FAPromise *promise = result;
                NSAssert(promise != self, @"A promise referencing itself causes an unbreakable retain cycle");
                FAWeakSelf;
                self.state = FAPromiseStatePending;
                self.result = [promise thenOnQueue:self.synchronizationQueue onFulfilled:^id(id value) {
                    FAStrongSelf;
                    if (strongSelf != nil) {
                        [strongSelf transition:value];
                    }
                    return value;
                } onRejected:^id(NSError *reason) {
                    FAStrongSelf;
                    if (strongSelf != nil) {
                        [strongSelf transition:reason];
                    }
                    return reason;
                }];
            } else if ([result isKindOfClass:[NSError class]]) {
                self.state = FAPromiseStateRejected;
                self.result = result;
                for (FARejectBlock rejected in self.onRejected) {
                    rejected(result);
                }
                [self.onFulfilled removeAllObjects];
                [self.onRejected removeAllObjects];
            } else {
                self.state = FAPromiseStateFulfilled;
                self.result = result;
                for (FAFulfillBlock fulfilled in self.onFulfilled) {
                    fulfilled(result);
                }
                [self.onFulfilled removeAllObjects];
                [self.onRejected removeAllObjects];
            }
            break;
            
        default:
            return;
    }
}

- (FAPromise *)thenOnFulfilled:(id (^)(id))onFulfilled onRejected:(id (^)(NSError*))onRejected {
    return [self thenOnQueue:[FAGCDQueue main] onFulfilled:onFulfilled onRejected:onRejected];
}

- (FAPromise *)thenOnQueue:(id<FADispatchQueue>)thenQueue onFulfilled:(id (^)(id))onFulfilled onRejected:(id (^)(NSError*))onRejected {
    return [[FAPromise alloc] initWithParent:self synchronizationQueue:self.synchronizationQueue resolver:^(FAResolveBlock resolve) {
        FAFulfillBlock fulfiller = ^(id value) {
            [thenQueue dispatch:^{
                id result = onFulfilled(value);
                resolve(result);
            }];
        };
        FARejectBlock rejecter = ^(NSError *reason) {
            [thenQueue dispatch:^{
                id result = onRejected(reason);
                resolve(result);
            }];
        };
        
        FASynchronizeWrite(self, ^(FAPromise *parent) {
            switch (parent.state) {
                case FAPromiseStatePending:
                    [parent.onFulfilled addObject:[fulfiller copy]];
                    [parent.onRejected addObject:[rejecter copy]];
                    break;
                    
                default:
                    if ([parent.result isKindOfClass:[FAPromise class]]) {
                        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:@"Promise must have a success or failure result when not pending"
                                                     userInfo:nil];
                    } else if ([parent.result isKindOfClass:[NSError class]]) {
                        rejecter(parent.result);
                    } else if (parent.result != nil) {
                        fulfiller(parent.result);
                    } else {
                        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:@"Promise is required to have a result when not pending"
                                                     userInfo:nil];
                    }
                    break;
            }
        });
    }];
}

- (FAPromise *)then:(id (^)(id))onFulfilled {
    return [self
            thenOnFulfilled:onFulfilled
            onRejected:^id(NSError *reason) {
                return reason;
            }];
}

- (FAPromise *)thenWithContext:(id)context onFulfilled:(id (^)(id, id))onFulfilled {
    FAWeak(context, weakContext);
    return [self
            thenOnFulfilled:^id(id value) {
                FAStrong(weakContext, strongContext);
                if (strongContext == nil) return [NSError fa_promiseContextUnavailableError];
                return onFulfilled(strongContext, value);
            }
            onRejected:^id(NSError *reason) {
                return reason;
            }];
}

- (FAPromise *)handleValue:(void (^)(id))onFulfilled {
    return [self
            thenOnFulfilled:^id(id value) {
                onFulfilled(value);
                return value;
            }
            onRejected:^id(NSError *reason) {
                return reason;
            }];
}

- (FAPromise *)handleValueWithContext:(id)context onFulfilled:(void (^)(id, id))onFulfilled {
    FAWeak(context, weakContext);
    return [self
            thenOnFulfilled:^id(id value) {
                FAStrong(weakContext, strongContext);
                if (strongContext == nil) return [NSError fa_promiseContextUnavailableError];
                onFulfilled(strongContext, value);
                return value;
            }
            onRejected:^id(NSError *reason) {
                return reason;
            }];
}

- (FAPromise *)catchError:(void (^)(NSError*))onRejected {
    return [self
            thenOnFulfilled:^id(id value) {
                return value;
            }
            onRejected:^id(NSError *reason) {
                onRejected(reason);
                return reason;
            }];
}

- (FAPromise *)catchErrorWithContext:(id)context onRejected:(void (^)(id, NSError*))onRejected {
    FAWeak(context, weakContext);
    return [self
            thenOnFulfilled:^id(id value) {
                return value;
            }
            onRejected:^id(NSError *reason) {
                FAStrong(weakContext, strongContext);
                if (strongContext != nil) {
                    onRejected(strongContext, reason);
                }
                return reason;
            }];
}

- (FAPromise *)recoverFromError:(id (^)(NSError*))onRejected {
    return [self
            thenOnFulfilled:^id(id value) {
                return value;
            }
            onRejected:onRejected];
}

- (FAPromise *)recoverFromErrorWithContext:(id)context onRejected:(id (^)(id, NSError*))onRejected {
    FAWeak(context, weakContext);
    return [self
            thenOnFulfilled:^id(id value) {
                return value;
            }
            onRejected:^id(NSError *reason) {
                FAStrong(weakContext, strongContext);
                if (strongContext == nil)  {
                    return reason;
                } else {
                    return onRejected(strongContext, reason);
                }
            }];
}

- (FAPromise *)finally:(void (^)())onFinally {
    return [self
            thenOnFulfilled:^id(id value) {
                onFinally();
                return value;
            }
            onRejected:^id(NSError *reason) {
                onFinally();
                return reason;
            }];
}

- (FAPromise *)finallyWithContext:(id)context onFinally:(void (^)(id))onFinally {
    FAWeak(context, weakContext);
    return [self
            thenOnFulfilled:^id(id value) {
                FAStrong(weakContext, strongContext);
                if (strongContext != nil) {
                    onFinally(strongContext);
                }
                return value;
            }
            onRejected:^id(NSError *reason) {
                FAStrong(weakContext, strongContext);
                if (strongContext != nil) {
                    onFinally(strongContext);
                }
                return reason;
            }];
}

@end
