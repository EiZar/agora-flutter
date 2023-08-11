import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var mainCoordinator: AppCoordinator?
    override func application(
    _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let flutterViewController: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        let channel = FlutterMethodChannel(name: "native_communication.channel", binaryMessenger: flutterViewController.binaryMessenger)
        
        channel.setMethodCallHandler({(call: FlutterMethodCall, result: FlutterResult) -> Void in
            guard call.method == "showNativeView" else {
                result(FlutterMethodNotImplemented)
                return
            }
            if let args = call.arguments as? Dictionary<String, Any>,
               let token = args["token"] as? String {
                let dataShared = UserDefaults(suiteName: "group.com.clsm.agora")
                dataShared!.set(token, forKey: "token")
                dataShared!.synchronize()
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
//            let token = call.arguments as! String
            result(FlutterError(code: "Native",
                                    message: "Native info Available",
                                    details: nil))
            self.mainCoordinator?.start()
        })
        let navigationController = UINavigationController(rootViewController: flutterViewController)
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        mainCoordinator = AppCoordinator(navigationController: navigationController)
        window?.makeKeyAndVisible()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
}
