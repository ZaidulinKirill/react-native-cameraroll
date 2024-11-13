/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTBridge.h>
#import <React/RCTURLRequestHandler.h>

@class PHPhotoLibrary;

#if RCT_NEW_ARCH_ENABLED
#else

@interface RNCAssetsLibraryRequestHandler : NSObject <RCTURLRequestHandler>

@end

#endif