import Photos


@objc(Cameraroll)
class Cameraroll: NSObject {
    @objc(getAssets:withResolver:withRejecter:)
    func getAssets(params: [String: Any], resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let skip = params["skip"] as? Int
        let limit = params["limit"] as? Int
        let sortBy = params["sortBy"] as? [[String: Any]]
        let select = params["select"] as? [String]
        let assetType = params["assetType"] as? String
        
        let options = PHFetchOptions()
        options.sortDescriptors = sortBy?.map({ sortDict in
            NSSortDescriptor(key: sortDict["key"] as? String, ascending: sortDict["asc"] as! Bool)
        })

        var predicates = [NSPredicate]()
        if (assetType == "image") {
            predicates.append(NSPredicate(format: "mediaType == %d",  PHAssetMediaType.image.rawValue))
        }
        
        if (assetType == "video") {
            predicates.append(NSPredicate(format: "mediaType == %d",  PHAssetMediaType.video.rawValue))
        }
        
        if (predicates.count > 0) {
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        let result = PHAsset.fetchAssets(with: options)

        let from = skip ?? 0
        let to = min((skip ?? 0) + (limit ?? result.count), result.count) - 1

        var assets = [PHAsset]()
        if (from < result.count) {
            let indexes = Array(from...to)
            result.enumerateObjects(at: IndexSet(indexes)) { (asset, _, _) in
                assets.append(asset)
            }
        }

        let includes = [
            "id": select == nil || select!.contains("id"),
            "name": select?.contains("name") ?? false,
            "type": select?.contains("type") ?? false,
            "size": select?.contains("size") ?? false,
            "ext": select?.contains("ext") ?? false,
            "isFavourite": select?.contains("isFavourite") ?? false
        ]
        
        let items = assets.map({ asset in
            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first
            let size = resource?.value(forKey: "fileSize") as? CLong
            let originalFilename = resource?.originalFilename
            let filename = asset.value(forKey: "filename") as? NSString
            let ext = filename?.pathExtension

            var dict = [String: Any]()
            if (includes["id"]!) { dict["id"] = asset.localIdentifier }
            if (includes["name"]!) { dict["name"] = originalFilename ?? "" }
            if (includes["type"]!) { dict["type"] = asset.mediaType.rawValue }
            if (includes["size"]!) { dict["size"] = size ?? -1 }
            if (includes["ext"]!) { dict["ext"] = ext ?? "" }
            if (includes["isFavourite"]!) { dict["isFavourite"] = asset.isFavorite }
            
            return dict
        })

        resolve([
            "total": result.count,
            "items": items
        ])
    }
    
    @objc(editAsset:withValues:withResolver:withRejecter:)
    func editAsset(id: String, values: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", id)
        fetchOptions.fetchLimit = 1

        let result = PHAsset.fetchAssets(with: fetchOptions)
        guard let asset = result.firstObject else {
            reject("Not found", "Asset not found", nil);
            return
        }
        
        let isFavourite = values["isFavourite"] as? Bool
                
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            if (isFavourite != nil) {
                request.isFavorite = isFavourite!
            }
        }, completionHandler: { success, error in
            if success {
                resolve(true)
            } else {
                reject("Error", error.debugDescription, nil)
            }
        })
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
