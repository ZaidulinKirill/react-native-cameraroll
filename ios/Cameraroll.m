#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Cameraroll, NSObject)

RCT_EXTERN_METHOD(getAssets:(NSDictionary *)params
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
