import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        let imageChannel = FlutterMethodChannel.init(
            name: "com.rizkyeky.guestimage",
            binaryMessenger: controller.binaryMessenger
        )
        
        let guestImage = GuestImage()
        
        imageChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "initModel":
                let data = guestImage.initModel(arguments: call.arguments)
                result(data)
            case "processImage":
                let data = guestImage.processImage(arguments: call.arguments)
                result(data)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
