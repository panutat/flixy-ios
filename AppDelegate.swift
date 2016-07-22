import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Fabric
import Crashlytics
import IQKeyboardManagerSwift
import AWSSNS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Setup Fabric/Crashlytics
        // Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self()])

        // Setup AWS
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWS_COGNITO_REGION_TYPE, identityPoolId: AWS_COGNITO_IDENTITY_POOL_ID)
        let configuration = AWSServiceConfiguration(region: AWS_DEFAULT_SERVICE_REGION_TYPE, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

        // Setup keyboard manager
        IQKeyboardManager.sharedManager().enable = true

        // Setup Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("didReceiveRemoteNotification: \(userInfo)")
    }

    func getDeviceTokenString(deviceToken: NSData) -> String {
        let characterSet: NSCharacterSet = NSCharacterSet(charactersInString: "<>")
        let deviceTokenString: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet(characterSet)
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        return deviceTokenString
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceToken = self.getDeviceTokenString(deviceToken)

        let currentViewController = self.window!.currentViewController() as! CommonViewController
        currentViewController.updatePushNotification(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error.localizedDescription)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification:fetchCompletionHandler: \(userInfo)")

        if let payload = userInfo["payload"] as? Dictionary<String, AnyObject> {
            let currentViewController = self.window!.currentViewController() as! CommonViewController
            currentViewController.handleNotificationPayload(payload)
        }

        completionHandler(UIBackgroundFetchResult.NewData)
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        if identifier == "READ_IDENTIFIER" {
            print("User selected 'Read'")
        } else if identifier == "DELETE_IDENTIFIER" {
            print("User selected 'Delete'")
        }

        completionHandler()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Clear badge count
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0

        // Setup Facebook
        FBSDKAppEvents.activateApp()
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        // Setup Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

}
