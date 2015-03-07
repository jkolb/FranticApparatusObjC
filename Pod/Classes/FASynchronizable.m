//
// FASynchronizable.m
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
#import "FADispatchQueue.h"
#import "FAMacro.h"


void FASynchronizeRead(id<FASynchronizable> synchronizable, void (^block)(id)) {
    FAWeak(synchronizable, weakSynchronizable);
    [[synchronizable synchronizationQueue] dispatch:^{
        FAStrong(weakSynchronizable, strongSynchronizable);
        if (strongSynchronizable == nil) return;
        block(strongSynchronizable);
    }];
}

id FASynchronizeReadResult(id<FASynchronizable> synchronizable, id (^block)(id)) {
    id __block result = nil;
    [[synchronizable synchronizationQueue] dispatchAndWait:^{
        result = block(synchronizable);
    }];
    return result;
}

void FASynchronizeWrite(id<FASynchronizable> synchronizable, void (^block)(id)) {
    FAWeak(synchronizable, weakSynchronizable);
    [[synchronizable synchronizationQueue] dispatchSerialized:^{
        FAStrong(weakSynchronizable, strongSynchronizable);
        if (strongSynchronizable == nil) return;
        block(strongSynchronizable);
    }];
}
