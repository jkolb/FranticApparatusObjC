//
// FAPromise.h
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

#import "FASynchronizable.h"


typedef void (^FAFulfillBlock)(id);
typedef void (^FARejectBlock)(NSError*);
typedef BOOL (^FAIsCancelledBlock)();


@protocol FADispatchQueue;


@interface FAPromise : NSObject

- (instancetype)initWithResolver:(void (^)(FAFulfillBlock fulfill, FARejectBlock reject, FAIsCancelledBlock isCancelled))resolver;

- (FAPromise *)thenOnFulfilled:(id (^)(id))onFulfilled onRejected:(id (^)(NSError*))onRejected;

- (FAPromise *)thenOnQueue:(id<FADispatchQueue>)thenQueue onFulfilled:(id (^)(id))onFulfilled onRejected:(id (^)(NSError*))onRejected;

- (FAPromise *)then:(id (^)(id))onFulfilled;

- (FAPromise *)thenWithContext:(id)context onFulfilled:(id (^)(id, id))onFulfilled;

- (FAPromise *)handleValue:(void (^)(id))onFulfilled;

- (FAPromise *)handleValueWithContext:(id)context onFulfilled:(void (^)(id, id))onFulfilled;

- (FAPromise *)catchError:(void (^)(NSError*))onRejected;

- (FAPromise *)catchErrorWithContext:(id)context onRejected:(void (^)(id, NSError*))onRejected;

- (FAPromise *)recoverFromError:(id (^)(NSError*))onRejected;

- (FAPromise *)recoverFromErrorWithContext:(id)context onRejected:(id (^)(id, NSError*))onRejected;

- (FAPromise *)finally:(void (^)())onFinally;

- (FAPromise *)finallyWithContext:(id)context onFinally:(void (^)(id))onFinally;

@end
