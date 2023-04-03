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
        let mediaType = params["mediaType"] as? String
        let totalOnly = params["totalOnly"] as? Bool
        
        let options = PHFetchOptions()
        options.sortDescriptors = sortBy?.map({ sortDict in
            NSSortDescriptor(key: sortDict["key"] as? String, ascending: sortDict["asc"] as! Bool)
        })

        var predicates = [NSPredicate]()
        if (mediaType == "image") {
            predicates.append(NSPredicate(format: "mediaType == %d",  PHAssetMediaType.image.rawValue))
        }
        
        if (mediaType == "video") {
            predicates.append(NSPredicate(format: "mediaType == %d",  PHAssetMediaType.video.rawValue))
        }
        
        if (predicates.count > 0) {
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        if (skip == nil && limit != nil && totalOnly != true) {
            options.fetchLimit = limit!
        }

        let result = PHAsset.fetchAssets(with: options)
        if (totalOnly == true) {
            resolve(["total": result.count])
            return
        }

        var assets = [PHAsset]()
        
        if (skip != nil) {
            let from = skip!
            let to = min((from) + (limit ?? result.count), result.count) - 1

            if (from < result.count) {
                let indexes = Array(from...to)
                result.enumerateObjects(at: IndexSet(indexes)) { (asset, _, _) in
                    assets.append(asset)
                }
            }
        } else {
            result.enumerateObjects { (asset, _, _) in
                assets.append(asset)
            }
        }

        let includes = [
            "id": select == nil || select!.contains("id"),
            "name": select?.contains("name") ?? false,
            "mediaType": select?.contains("mediaType") ?? false,
            "size": select?.contains("size") ?? false,
            "creationDate": select?.contains("creationDate") ?? false,
            "uri": select?.contains("uri") ?? false,
            "isFavorite": select?.contains("isFavorite") ?? false
        ]
        
        let items = assets.map({ asset in
            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first
            let size = resource?.value(forKey: "fileSize") as? CLong
            let originalFilename = resource?.originalFilename
            let filename = asset.value(forKey: "filename") as? NSString
            let creationDate = asset.creationDate
            
            var dict = [String: Any]()
            if (includes["id"]!) { dict["id"] = asset.localIdentifier }
            if (includes["name"]!) { dict["name"] = originalFilename ?? "" }
            if (includes["mediaType"]!) { dict["mediaType"] = asset.mediaType.rawValue }
            if (includes["size"]!) { dict["size"] = size ?? -1 }
            if (includes["creationDate"]!) { dict["creationDate"] = creationDate?.timeIntervalSince1970 ?? -1 }
            if (includes["isFavorite"]!) { dict["isFavorite"] = asset.isFavorite }
            if (includes["uri"]!) { dict["uri"] = "ph://\(asset.localIdentifier)" }
            
            return dict
        })

        resolve([ "items": items ])
    }
    
    @objc(editIsFavorite:withValue:withResolver:withRejecter:)
    func editIsFavorite(id: String, value: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else {
            reject("Not found", "Asset not found", nil);
            return
        }
        
        let isFavorite = value
                
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = isFavorite
        }, completionHandler: { success, error in
            if success {
                resolve(["success": true])
            } else {
                reject("Error", error.debugDescription, nil)
            }
        })
    }
    
    @objc(deleteAssets:withResolver:withRejecter:)
    func deleteAssets(ids: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        if (fetchResult.count == 0) {
            resolve(["success": true])
            return
        }
        
        var assets = [PHAsset]()
        fetchResult.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }, completionHandler: { (success, error) in
            resolve(["success": success])
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
