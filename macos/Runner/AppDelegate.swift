import Cocoa
import FlutterMacOS
// import CoreML
// import Vision

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
	private var guestImage = GuestImage()
    
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard let app = NSApplication.shared.delegate as? FlutterAppDelegate else { return }
        guard let controller = findFlutterViewController(app.mainFlutterWindow.contentViewController) else { return }
        
        let imageChannel = FlutterMethodChannel.init(
            name: "com.rizkyeky.guestimage",
            binaryMessenger: controller.engine.binaryMessenger
        )
        
        imageChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "initModel":
               let data = self.guestImage.initModel(arguments: call.arguments)
                result(data)
            case "processImage":
               let data = self.guestImage.processImage(arguments: call.arguments)
                result(data)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
    
    private func findFlutterViewController(_ viewController: NSViewController?) -> FlutterViewController? {
        guard let vc = viewController else {
            return nil
        }
        if let fvc = vc as? FlutterViewController {
            return fvc
        }
        for child in vc.children {
            let fvc = findFlutterViewController(child)
            if fvc != nil {
                return fvc
            }
        }
        return nil
    }
}
