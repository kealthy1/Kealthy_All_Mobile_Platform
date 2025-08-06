import Flutter
import UIKit
import GoogleMaps
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register for remote notifications
        application.registerForRemoteNotifications()

        // Configure Google Maps API key
        GMSServices.provideAPIKey("AIzaSyD1MUoakZ0mm8WeFv_GK9k_zAWdGk5r1hA") // Replace with your actual API key

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass device token to Firebase
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Called when a notification is delivered to a foreground app
    override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    // Show the notification in the foreground
    if #available(iOS 14.0, *) {
        completionHandler([.badge, .sound, .banner, .list])
    } else {
        completionHandler([.badge, .sound, .alert])
    }
}

    // Called when the user interacts with a notification (e.g., taps on it)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("Notification received with identifier: \(response.notification.request.identifier)")
        completionHandler()
    }
}