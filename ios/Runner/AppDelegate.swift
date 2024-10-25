import Flutter
import UIKit
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GeneratedPluginRegistrant.register(with: self)

          // Flutter method channel for switching sessions
          let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
          let audioChannel = FlutterMethodChannel(name: "com.example.myapp/audio",
                                                  binaryMessenger: controller.binaryMessenger)

          audioChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "setAudioSession" {
              self.configureAudioSession(record: call.arguments as? Bool ?? false)
              result(nil)
            } else {
              result(FlutterMethodNotImplemented)
            }
          })

          configureAudioSession(record: false)  // Initial playback session

          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    private func configureAudioSession(record: Bool) {
        do {
          let audioSession = AVAudioSession.sharedInstance()

          if record {
            // Set up session for recording with main speaker output
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            print("Configured session for recording and playback on main speaker.")
          } else {
            // Initial playback only session
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            print("Configured session for playback only on main speaker.")
          }

          try audioSession.setActive(true)
        } catch {
          print("Failed to configure audio session: \(error)")
        }
      }


    private func setAudioSession() {
        do {
               let audioSession = AVAudioSession.sharedInstance()
               try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
               try audioSession.overrideOutputAudioPort(.speaker)
               try audioSession.setActive(true)
               print("Configured for continuous voice-to-voice on main speaker.")
           } catch {
               print("Failed to configure audio session: \(error)")
           }
      }


    @objc private func handleAudioRouteChange(notification: Notification) {
        // Reapply audio session settings upon route change
        configureAudioSession()
      }

      deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
}
}