import Photos

@objc(Cameraroll)
public class Cameraroll: NSObject {
    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(getAssets:withResolver:withRejecter:)
    func getAssets(params: [String: Any], resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let skip = params["skip"] as? Int
        let limit = params["limit"] as? Int
        let sortBy = params["sortBy"] as? [[String: Any]]
        let select = params["select"] as? [String]
        let mediaType = params["mediaType"] as? String
        let collectionType = params["collectionType"] as? Int
        let collectionSubType = params["collectionSubType"] as? Int
        let ids = params["ids"] as? [String]
        let totalOnly = params["totalOnly"] as? Bool

        let options = PHFetchOptions()
        options.sortDescriptors = sortBy?.map { sortDict in
            NSSortDescriptor(key: sortDict["key"] as? String, ascending: sortDict["asc"] as! Bool)
        }

        var predicates = [NSPredicate]()
        if mediaType == "image" {
            predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue))
        }

        if mediaType == "video" {
            predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue))
        }
        
        if ids != nil {
            predicates.append(NSPredicate(format: "localIdentifier IN %@", ids!))
        }
        
        if predicates.count > 0 {
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        if skip == nil && limit != nil && totalOnly != true {
            options.fetchLimit = limit!
        }

        var collection: PHAssetCollection? = nil
        if collectionType != nil && collectionSubType != nil {
            PHAssetCollectionSubtype.smartAlbumVideos
            collection = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType(rawValue: collectionType!)!, subtype: PHAssetCollectionSubtype(rawValue: collectionSubType!)!, options: nil).firstObject
        }

        let result = collection == nil
            ? PHAsset.fetchAssets(with: options)
            : PHAsset.fetchAssets(in: collection!, options: options)

        if totalOnly == true {
            resolve(["total": result.count])
            return
        }

        var assets = [PHAsset]()

        if skip != nil {
            let from = skip!
            let to = min(from + (limit ?? result.count), result.count) - 1

            if from < result.count {
                let indexes = Array(from ... to)
                result.enumerateObjects(at: IndexSet(indexes)) { asset, _, _ in
                    assets.append(asset)
                }
            }
        } else {
            result.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
        }

        let includeId = select == nil || select!.contains("id")
        let includeName = select?.contains("name") ?? false
        let includeMediaType = select?.contains("mediaType") ?? false
        let includeSize = select?.contains("size") ?? false
        let includeCreatedAt = select?.contains("createdAt") ?? false
        let includeIsFavorite = select?.contains("isFavorite") ?? false
        let includeDuration = select?.contains("duration") ?? false
        let includeWidth = select?.contains("width") ?? false
        let includeHeight = select?.contains("height") ?? false

        let includes = [
            "id": includeId,
            "name": includeName,
            "mediaType": includeMediaType,
            "size": includeSize,
            "createdAt": includeCreatedAt,
            "isFavorite": includeIsFavorite,
            "duration": includeDuration,
            "width": includeWidth,
            "height": includeHeight,
        ]

        let items = assets.map { asset in
            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first
            let size = resources.map { $0.value(forKey: "fileSize") as? Int64 ?? 0 }.reduce(0) { acc, item in acc + item }
            let originalFilename = resource?.originalFilename
            let createdAt = asset.creationDate

            var dict = [String: Any]()
            if includes["id"]! { dict["id"] = asset.localIdentifier }
            if includes["name"]! { dict["name"] = originalFilename ?? "" }
            if includes["mediaType"]! { dict["mediaType"] = asset.mediaType.rawValue }
            if includes["size"]! { dict["size"] = size }
            if includes["createdAt"]! { dict["createdAt"] = createdAt?.timeIntervalSince1970 ?? -1 }
            if includes["isFavorite"]! { dict["isFavorite"] = asset.isFavorite }
            if includes["duration"]! { dict["duration"] = asset.duration }
            if includes["width"]! { dict["width"] = asset.pixelWidth }
            if includes["height"]! { dict["height"] = asset.pixelHeight }

            return dict
        }

        resolve(["items": items])
    }

    @objc(editIsFavorite:withValue:withResolver:withRejecter:)
    func editIsFavorite(id: String, value: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else {
            reject("Not found", "Asset not found", nil)
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
    func deleteAssets(ids: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        if fetchResult.count == 0 {
            resolve(["success": true])
            return
        }

        var assets = [PHAsset]()
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }, completionHandler: { success, _ in
            resolve(["success": success])
        })
    }

    @objc(getAssetVideoInfo:withResolver:withRejecter:)
    func getAssetVideoInfo(id: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter _: RCTPromiseRejectBlock) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)

        if fetchResult.count > 0 {
            let asset = fetchResult.firstObject

            let options = PHVideoRequestOptions()
            options.version = .original

            PHImageManager.default().requestAVAsset(forVideo: asset!, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset as? AVURLAsset else {
                    resolve(nil)
                    return
                }

                let urlAsset = avAsset.url

                do {
                    let videoData = try Data(contentsOf: urlAsset)
                    let videoAsset = AVAsset(url: urlAsset)

                    if let videoTrack = videoAsset.tracks(withMediaType: .video).first {
                        let videoBitrate = videoTrack.estimatedDataRate
                        let videoWidth = videoTrack.naturalSize.width
                        let videoHeight = videoTrack.naturalSize.height

                        resolve([
                            "bitrate": videoBitrate,
                            "width": videoWidth,
                            "height": videoHeight,
                        ] as [String: Any]
                        )
                    } else {
                        resolve(nil)
                    }
                } catch {
                    resolve(nil)
                }
            }
        } else {
            resolve(nil)
        }
    }

    @objc(extractThumbnail:withFilename:withWidth:withHeight:withResolver:withRejecter:)
    func extractThumbnail(id: String, filename: String, width: Int, height: Int, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)

        if fetchResult.count > 0 {
            let asset = fetchResult.firstObject

            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true

            let targetSize = (width == -1 || height == -1) ? PHImageManagerMaximumSize : CGSize(width: width, height: height)
            PHImageManager.default().requestImage(for: asset!, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, error in
                if (image == nil) {
                    reject("Error", "Unexpected error", nil)
                    return
                }

                if let data = image!.jpegData(compressionQuality: 0.8) {
                    do {
                        let url = URL(fileURLWithPath: filename)
                        try data.write(to: url)

                        resolve(nil)
                    }
                    catch {
                        reject("Error", "Unexpected error", nil)
                    }
                    
                    
                } else {
                    reject("Error", "Unexpected error", nil)
                }
            }
        } else {
            reject("Error", "Asset not found", nil)
        }
    }

    @objc(saveAssets:withResolver:withRejecter:)
    func saveAssets(files: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard checkPhotoLibraryAccess(reject: reject) else {
            return
        }

        for uri in files {
            let url: URL
            if uri.contains("://") {
                url = URL(string: uri)!;
            } else {
                url = URL(fileURLWithPath: uri)
            }

            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                } else {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                }
            }
        }
        
        resolve(nil)
    }


    @objc(fetchAssetFullSizeURL:withResolver:withRejecter:)
    func fetchAssetFullSizeURL(id: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)

        if fetchResult.count > 0 {
            let asset = fetchResult.firstObject!

            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { _ in true }
            
            asset.requestContentEditingInput(with: options) { (input, _) in
                guard let url = input?.fullSizeImageURL else {
                    resolve(["url": nil])
                    return
                }

                resolve(["url": url.absoluteString])
            }
        } else {
            reject("Error", "Asset not found", nil)
        }
    }

    func checkPhotoLibraryAccess(reject: RCTPromiseRejectBlock?) -> Bool {
        var statuses = [PHAuthorizationStatus.authorized]
        if #available(iOS 14, *) {
            statuses.append(.limited)
        }

        let status = PHPhotoLibrary.authorizationStatus()
        let isAllowed = statuses.contains(status)

        if !isAllowed && reject != nil {
            reject!("Permission denied", "Photos access permission required", nil)
        }

        return isAllowed
    }
}
