// SimilarImageDetector.m
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(SimilarImageDetector, NSObject)

RCT_EXTERN_METHOD(findSimilarImagesFromGallery:(double)interval
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end

