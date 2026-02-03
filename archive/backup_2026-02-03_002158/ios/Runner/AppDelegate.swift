import Flutter
import UIKit
// If you use Google Maps on iOS, import GoogleMaps and provide your API key here.
// Add pod 'GoogleMaps' via platform-specific instructions if required.
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Provide your Google Maps API key for iOS (replace the placeholder)
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
