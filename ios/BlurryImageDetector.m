// // BlurryImageDetector.m
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(BlurryImageDetector, NSObject)

RCT_EXTERN_METHOD(findBlurryImagesFromGallery:(NSArray *)previousIds
                  withThreshold:(double)threshold
                  withItemsPerPage:(int)itemsPerPage
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end


