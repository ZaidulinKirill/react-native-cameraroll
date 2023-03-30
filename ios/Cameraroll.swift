import Photos


@objc(Cameraroll)
class Cameraroll: NSObject {
    @objc(getAssets:withResolver:withRejecter:)
    func getAssets(params: [String: Any], resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let limit = params["limit"] as? Int
        let sortBy = params["sortBy"] as? [[String: Any]]
        
        let options = PHFetchOptions()
        options.sortDescriptors = sortBy?.map({ sortDict in
            NSSortDescriptor(key: sortDict["key"] as? String, ascending: sortDict["asc"] as! Bool)
        })
        options.fetchLimit = limit ?? 0
        
        let result = PHAsset.fetchAssets(with: options)
        var assets = [PHAsset]()

        result.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }

        resolve(assets)
    }
    
    func checkPhotoLibraryAccess(reject: RCTPromiseRejectBlock?) -> Bool {
        var statuses = [PHAuthorizationStatus.authorized]
        if #available(iOS 14, *) {
            statuses.append(.limited)
        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        let isAllowed = statuses.contains(status)
        
        if (!isAllowed && reject != nil) {
            reject!("Permission denied", "Photos access permission required", nil);
        }

        return isAllowed
    }
}
