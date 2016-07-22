import UIKit
import Firebase
import MapKit
import AWSSNS

class CommonTableViewController: UITableViewController {

    // MARK: Local Variables

    var user: User!
    var settings: UserSettings!
    var reachable: Bool = false

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupReachability()
    }

    // MARK: Helpers

    func logout() {
        // Clear user data from local storage
        SpinnerView.show("Logging out")

        // Cleanup session
        UserUtil.logout()

        // Logout from Firebase
        FbaseDataService.ds.logout()

        // Delay dismiss to display spinner
        Delay.run(Delay.Logout, withCompletion: {
            self.view.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        })
    }

    func checkCurrentUser() {
        if let user = UserUtil.getCurrent() {
            self.user = user
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func checkUserSettings() {
        if let settings = UserUtil.getSettings() {
            self.settings = settings
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func showAlert(title: String, msg: String) -> AlertViewController {
        let alertView = AlertViewController()
        alertView.show(self, title: title, text: msg, buttonText: ALERT_MESSAGE_TITLE_OK)
        return alertView
    }

    func showConfirm(title: String, msg: String) -> AlertViewController {
        let confirmView = AlertViewController()
        confirmView.danger(self, title: title, text: msg, buttonText: ALERT_MESSAGE_TITLE_CONFIRM, cancelButtonText: ALERT_MESSAGE_BUTTON_CANCEL)
        return confirmView
    }

    func convertSnapshotToDictionary(snapshot: FDataSnapshot) -> Dictionary<String, AnyObject> {
        return snapshot.value as! Dictionary<String, AnyObject>
    }

    func getCurrentUser() -> Dictionary<String, AnyObject> {
        if NSUserDefaults.standardUserDefaults().valueForKey(CURRENT_USER) != nil {
            return NSUserDefaults.standardUserDefaults().valueForKey(CURRENT_USER) as! Dictionary<String, AnyObject>
        } else {
            return Dictionary<String, AnyObject>()
        }
    }

    func storeCurrentUser(user: Dictionary<String, AnyObject>) -> Void {
        NSUserDefaults.standardUserDefaults().setValue(user, forKey: CURRENT_USER)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func getUserSettings() -> Dictionary<String, AnyObject> {
        if NSUserDefaults.standardUserDefaults().valueForKey(USER_SETTINGS) != nil {
            return NSUserDefaults.standardUserDefaults().valueForKey(USER_SETTINGS) as! Dictionary<String, AnyObject>
        } else {
            return Dictionary<String, AnyObject>()
        }
    }

    func storeUserSettings(settings: Dictionary<String, AnyObject>) -> Void {
        NSUserDefaults.standardUserDefaults().setValue(settings, forKey: USER_SETTINGS)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func getRowIndexFromSender(source: AnyObject?, tableView: UITableView) -> Int {
        if source is UIButton {
            let position = source!.convertPoint(CGPointZero, toView: tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(position) {
                return indexPath.row
            }
        } else if source is UITapGestureRecognizer {
            let position = source!.locationInView(tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(position) {
                return indexPath.row
            }
        }
        return -1
    }

    func getCellIndexFromSender(source: AnyObject?, collectionView: UICollectionView) -> Int {
        if source is UIButton {
            let position = source!.convertPoint(CGPointZero, toView: collectionView)
            if let indexPath = collectionView.indexPathForItemAtPoint(position) {
                return indexPath.row
            }
        } else if source is UITapGestureRecognizer {
            let position = source!.locationInView(collectionView)
            if let indexPath = collectionView.indexPathForItemAtPoint(position) {
                return indexPath.row
            }
        }
        return -1
    }

    func setupReachability() -> Void {
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }

        reachability.whenReachable = {
            (reachability) in
            dispatch_async(dispatch_get_main_queue()) {
                self.reachable = true
                if reachability.isReachableViaWiFi() {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
            }
        }
        reachability.whenUnreachable = {
            (reachability) in
            dispatch_async(dispatch_get_main_queue()) {
                self.reachable = false
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_NETWORK_UNAVAILABLE)
            }
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    func gotoHomeView(location: CLLocation?) {
        if var viewController = self.presentingViewController {
            while viewController.presentingViewController != nil && !viewController.presentingViewController!.isKindOfClass(LoginViewController) {
                viewController = viewController.presentingViewController!
            }

            let homeViewController = viewController as! HomeViewController
            if let location = location {
                homeViewController.centerMapOnLocation(location)
            }
            homeViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func checkPushNotification() -> Void {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }

    func updatePushNotification(deviceToken: String?) -> Void {
        if let user = self.user {
            // Only update if device token is different
            if user.deviceToken != deviceToken {
                let sns = AWSSNS.defaultSNS()

                // Create new endpoint
                let request = AWSSNSCreatePlatformEndpointInput()
                request.token = deviceToken
                request.platformApplicationArn = "arn:aws:sns:us-east-1:916138528931:app/APNS_SANDBOX/FlixyDevelopment"
                sns.createPlatformEndpoint(request).continueWithBlock {
                    (task) -> AnyObject? in
                    if task.error == nil {

                        // Get endpointArn
                        let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                        let endpointArn = createEndpointResponse.endpointArn

                        // Update device token and endpoint arn in Firebase
                        FbaseDataService.ds.updateUserDeviceTokenAndEndpointArn(user.uid, deviceToken: deviceToken!, endpointArn: endpointArn!, withCompletionBlock: {
                            (error, ref) in
                            if error == nil {

                                // Update user data attributes in AWS SNS
                                let json = "{\"uid\":\"\(user.uid)\", \"email\":\"\(user.email)\"}"
                                let input = AWSSNSSetEndpointAttributesInput()
                                input.attributes = NSDictionary(object: json, forKey: "CustomUserData") as? [String : String]
                                input.endpointArn = endpointArn
                                sns.setEndpointAttributes(input).continueWithBlock({
                                    (task) -> AnyObject? in
                                    return nil
                                })

                                // Delete old endpoint if exists
                                if user.endpointArn != "" {
                                    let request = AWSSNSDeleteEndpointInput()
                                    request.endpointArn = user.endpointArn
                                    sns.deleteEndpoint(request).continueWithBlock({
                                        (task) -> AnyObject? in
                                        return nil
                                    })
                                }

                                // Update user
                                self.user.deviceToken = deviceToken
                                self.user.endpointArn = endpointArn
                                UserUtil.setCurrent(self.user)

                            }
                        })

                    }
                    return nil
                }

            }
        }
    }

}
