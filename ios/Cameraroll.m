#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Cameraroll, NSObject)

RCT_EXTERN_METHOD(getAssets:(NSDictionary *)params
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(editIsFavorite:(NSString *)id
                  withValue:(BOOL)value
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(deleteAssets:(NSArray *)ids
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getAssetVideoInfo:(NSString *) id
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
)

RCT_EXTERN_METHOD(saveAssets:(NSArray *) files
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
)

RCT_EXTERN_METHOD(saveThumbnail:(NSString *)id
                  withFilename: (NSString *)filename
                  withWidth: (int)width
                  withHeight: (int)height
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject
)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
