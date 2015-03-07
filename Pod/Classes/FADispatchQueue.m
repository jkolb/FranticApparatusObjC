//
// FADispatchQueue.m
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

#import "FADispatchQueue.h"


@interface FAGCDQueue ()

@property (nonatomic, readonly, strong) dispatch_queue_t queue;

@end


@implementation FAGCDQueue

- (instancetype)init {
    return [self initWithQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    NSParameterAssert(queue != nil);
    self = [super init];
    if (self == nil) return nil;
    _queue = queue;
    return self;
}

+ (instancetype)main {
    return [[self alloc] initWithQueue:dispatch_get_main_queue()];
}

+ (instancetype)serial:(NSString *)name {
    return [[self alloc] initWithQueue:dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
}

+ (instancetype)concurrent:(NSString *)name {
    return [[self alloc] initWithQueue:dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT)];
}

+ (instancetype)globalPriorityDefault {
    return [[self alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

+ (instancetype)globalPriorityBackground {
    return [[self alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
}

+ (instancetype)globalPriorityHigh {
    return [[self alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
}

+ (instancetype)globalPriorityLow {
    return [[self alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
}

- (void)dispatch:(void (^)())block {
    dispatch_async(self.queue, block);
}

- (void)dispatchAndWait:(void (^)())block {
    dispatch_sync(self.queue, block);
}

- (void)dispatchSerialized:(void (^)())block {
    dispatch_barrier_async(self.queue, block);
}

- (NSString *)description {
    return [NSString stringWithCString:dispatch_queue_get_label(self.queue) encoding:NSASCIIStringEncoding];
}

@end
