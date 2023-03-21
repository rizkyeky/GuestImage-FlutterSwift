//import Cocoa
//import FlutterMacOS
import CoreML
import Vision

class GuestImage {

    private var model: MLModel?

    func initModel(arguments: Any?) -> Bool {
        guard let path = arguments as? String else { return false }
        do {
            let modelc = try MLModel.compileModel(at: URL(fileURLWithPath: path))
            self.model = try MLModel.init(contentsOf: modelc)
            print("Success load model")
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func processImage(arguments: Any?) -> String {
        guard let path = arguments as? String else { return "nil" }
        guard let image = self.loadCGImage(fromPath: path) else {
            print("Failed to load image at path: \(path)")
            return "nil"
        }
        
        do {
            if (model != nil) {
                let imageConstraint = model!.modelDescription.inputDescriptionsByName["image"]!.imageConstraint!
                            
                let imageOptions: [MLFeatureValue.ImageOption: Any] = [
                    .cropAndScale: VNImageCropAndScaleOption.scaleFill.rawValue
                ]
                
                let featureValue = try MLFeatureValue(cgImage: image, constraint: imageConstraint, options: imageOptions)
                let featureProviderDict = try MLDictionaryFeatureProvider(dictionary: ["image" : featureValue])
                let prediction = try model!.prediction(from: featureProviderDict)
                let value = prediction.featureValue(for: "classLabel")?.stringValue
                
                return value ?? "nil"
            } else {
                print("Model is not initilize")
                return "nil"
            }
        } catch {
            return "nil"
        }
    }
    
    private func loadCGImage(fromPath path: String) -> CGImage? {
        let fileURL = URL(fileURLWithPath: path)
        
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            print("Failed to create image source from file: \(path)")
            return nil
        }
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to create CGImage from image source: \(path)")
            return nil
        }
        
        return cgImage
    }
}
