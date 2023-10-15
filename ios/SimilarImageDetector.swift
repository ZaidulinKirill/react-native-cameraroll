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

            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first
            let size = resources.map { $0.value(forKey: "fileSize") as? Int64 ?? 0 }.reduce(0) { acc, item in acc + item }
            let originalFilename = resource?.originalFilename
            let creationDate = asset.creationDate

            resuls.append([
                "id": asset.localIdentifier,
                "name": originalFilename ?? "",
                "creationDate": creationDate?.timeIntervalSince1970 ?? -1,
                "size": size,
            ])
        }

        return resuls
    }

    @objc(findSimilarImagesFromGallery:withResolver:withRejecter:)
    func findSimilarImagesFromGallery(interval: Double, resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
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
                let creationDate = (asset.creationDate?.timeIntervalSince1970 ?? 0)
                let timeOffset = currentGroupTime - creationDate

                if timeOffset < interval {
                    currentGroup.append(asset)
                } else {
                    if currentGroup.count > 1 {
                        groups.append(self.preprocessAssets(assets: currentGroup))
                    }

                    currentGroup = [asset]
                }

                currentGroupTime = creationDate
            }

            if currentGroup.count > 1 {
                groups.append(self.preprocessAssets(assets: currentGroup))
            }

            resolve(groups as NSArray)
        })
    }
}
