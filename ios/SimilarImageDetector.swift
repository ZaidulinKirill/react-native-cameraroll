import Photos

@objc(SimilarImageDetector)
public class SimilarImageDetector: NSObject {
    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }

    public func fetchImagesFromGallery(resultHandler: @escaping ([PHAsset]) -> Void) {
       PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.includeAssetSourceTypes = [.typeUserLibrary]

                let assets: PHFetchResult = PHAsset.fetchAssets(
                    with: .image, options: fetchOptions
                )

                var results: [PHAsset] = []

                for i in 0 ..< assets.count {
                    let asset = assets[i]
                    results.append(asset)
                }

              resultHandler(results)
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
            case .limited:
                print("Not allowed")
            @unknown default:
                print("Not allowed")
            }
        }
    }

    private func preprocessAssets(assets: [PHAsset]) -> [NSDictionary] {
        var resuls = [NSDictionary]()

        for i in 0 ..< assets.count {
            let asset = assets[i]
            
            let originalFilename = "" // resource?.originalFilename
            let createdAt = asset.creationDate
            
            resuls.append([
                "id": asset.localIdentifier,
                "createdAt": createdAt?.timeIntervalSince1970 ?? -1,
                "size": asset.pixelWidth * asset.pixelHeight / 5, //size,
            ])
        }

        return resuls
    }

    @objc(findSimilarImagesFromGallery:withResolver:withRejecter:)
    func findSimilarImagesFromGallery(interval: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        fetchImagesFromGallery(resultHandler: {
            (results: [PHAsset]) in
            if results.count == 0 {
                resolve([[NSDictionary]]() as NSArray)
                return
            }

            let sortedAssets = results

            var groups = [[NSDictionary]]()
            var currentGroup = [sortedAssets[0]]
            var currentGroupTime = sortedAssets[0].creationDate?.timeIntervalSince1970 ?? 0

            for i in 1 ..< sortedAssets.count {
                let asset = sortedAssets[i]
                let createdAt = (asset.creationDate?.timeIntervalSince1970 ?? 0)
                let timeOffset = currentGroupTime - createdAt

                if timeOffset < interval {
                    currentGroup.append(asset)
                } else {
                    if currentGroup.count > 1 {
                        groups.append(self.preprocessAssets(assets: currentGroup))
                    }

                    currentGroup = [asset]
                }

                currentGroupTime = createdAt
            }

            if currentGroup.count > 1 {
                groups.append(self.preprocessAssets(assets: currentGroup))
            }

            resolve(groups as NSArray)
        })
    }
}
