import Accelerate
import Metal
import MetalKit
import MetalPerformanceShaders
import MobileCoreServices
import Photos

@objc(BlurryImageDetector)
public class BlurryImageDetector: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool {
    return false
  }

  var mtlGlobalDevice: MTLDevice?
  var mtlGlobalCommandQueue: MTLCommandQueue?
  var pixelFormat: MTLPixelFormat

  override init() {
    mtlGlobalDevice = MTLCreateSystemDefaultDevice()
    pixelFormat = MTLPixelFormat.r8Unorm
    mtlGlobalCommandQueue = mtlGlobalDevice?.makeCommandQueue()

    super.init()
  }

  func getAssetThumbnail(asset: PHAsset) -> CGImage? {
    let manager = PHImageManager.default()
    let option = PHImageRequestOptions()
    option.isSynchronous = true
    var image: CGImage? = nil

    manager.requestImage(
      for: asset, targetSize: CGSize(width: 512, height: 512), contentMode: .aspectFit,
      options: option,
      resultHandler: { (result, info) -> Void in
        image = result?.cgImage
      })

    return image
  }

  func getTextureBytes(texture: MTLTexture) -> [UInt8] {
    let bytesPerPixel = 1
    let rowBytes = texture.width * bytesPerPixel
    var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * bytesPerPixel)
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)

    texture.getBytes(&bytes, bytesPerRow: rowBytes, from: region, mipmapLevel: 0)

    return bytes
  }

  func getImageBlurriness(assetImage: CGImage) -> Double {
    if mtlGlobalCommandQueue == nil || mtlGlobalDevice == nil {
      return -1
    }

    let mtlDevice = self.mtlGlobalDevice!
    let mtlCommandQueue = self.mtlGlobalCommandQueue!
    let mktTextureLoader = MTKTextureLoader(device: mtlDevice)

    do {
      let sourceTexture = try mktTextureLoader.newTexture(cgImage: assetImage, options: nil)

      guard let commandBuffer = mtlCommandQueue.makeCommandBuffer() else { return -1 }

      let imageConversion = MPSImageConversion(device: mtlDevice)
      let laplacian = MPSImageLaplacian(device: mtlDevice)
      // let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: mtlDevice)

      // 1) Convert source to grayscale format
      let grayscaleTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: pixelFormat, width: sourceTexture.width, height: sourceTexture.height,
        mipmapped: false)
      grayscaleTextureDescriptor.usage = [.shaderWrite, .shaderRead]

      guard let grayscaleTexture = mtlDevice.makeTexture(descriptor: grayscaleTextureDescriptor)
      else { return -1 }
      imageConversion.encode(
        commandBuffer: commandBuffer, sourceTexture: sourceTexture,
        destinationTexture: grayscaleTexture)

      // 2) Apply laplacian filter
      let laplacianTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: pixelFormat, width: sourceTexture.width, height: sourceTexture.height,
        mipmapped: false)
      laplacianTextureDescriptor.usage = [.shaderWrite, .shaderRead]

      guard let laplacianTexture = mtlDevice.makeTexture(descriptor: laplacianTextureDescriptor)
      else { return -1 }
      laplacian.encode(
        commandBuffer: commandBuffer, sourceTexture: grayscaleTexture,
        destinationTexture: laplacianTexture)

      // 3) Apply mean and variance filter
      /* let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 2, height: 1, mipmapped: false)
            varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]

            guard let varianceTexture = mtlDevice.makeTexture(descriptor: varianceTextureDescriptor) else { return -1; }
            meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: laplacianTexture, destinationTexture: varianceTexture)
            */
      // 4) Run filters and wait for results
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()

      let bytes = self.getTextureBytes(texture: laplacianTexture).map { Double($0) }
      var standartDeviation = 0.0
      var mean = 0.0

      if bytes.count < 10 {
        return -1
      }

      vDSP_normalizeD(bytes, 1, nil, 1, &mean, &standartDeviation, vDSP_Length(bytes.count))
      standartDeviation *= sqrt(Double(bytes.count) / Double(bytes.count - 1))

      return standartDeviation
    } catch {
      print(error)
      return -1
    }
  }

  func getAssetPath(asset: PHAsset, resultHandler: @escaping (URL?) -> Void) {
    asset.requestContentEditingInput(
      with: nil,
      completionHandler: {
        (result, _) in
        resultHandler(result?.fullSizeImageURL)
      })
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

  public func fetchImagesFromGallery(
    previousIds: [String], threshold: Double, itemsPerPage: Int, onFinished: @escaping ([PHAsset], [String]) -> Void
  ) {
    PHPhotoLibrary.requestAuthorization { (status) in
      switch status {
      case .authorized:
        let fetchOptions = PHFetchOptions()

        if (previousIds.count > 0) {
            fetchOptions.predicate = NSPredicate(format: "NOT (localIdentifier IN %@)", previousIds)
        }

        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary]

        let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let count: Int = assets.count < itemsPerPage ? assets.count : itemsPerPage
        var results = [PHAsset]()
        var processedIds = [String]()

        for i in 0..<count {
          autoreleasepool {
            let asset = assets[i]
            processedIds.append(asset.localIdentifier)

            let result = self.getAssetThumbnail(asset: asset)
            if let assetImage = result {
              let blurriness = self.getImageBlurriness(assetImage: assetImage)

              if blurriness < threshold && blurriness >= 0 {
                  results.append(asset)
              }
            }
          }
        }

        onFinished(results, processedIds)
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

  @objc(findBlurryImagesFromGallery:withThreshold:withItemsPerPage:withResolver:withRejecter:)
  public func findBlurryImagesFromGallery(
    previousIds: [String], threshold: Double, itemsPerPage: Int, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock
  ) {
    self.fetchImagesFromGallery(
      previousIds: previousIds,
      threshold: threshold,
      itemsPerPage: itemsPerPage,
      onFinished: {
        (assets: [PHAsset], processedIds: [String]) in
          let items = self.preprocessAssets(assets: assets) as NSArray
          
          resolve([
            "items": items,
            "processedIds": processedIds,
        ])
      })
  }
}
