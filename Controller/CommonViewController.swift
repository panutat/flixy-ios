import UIKit
import Firebase
import MapKit
import AWSSNS

class CommonViewController: UIViewController {

    // MARK: Local Variables

    var user: User!
    var settings: UserSettings!
    var reachable: Bool = false

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup network check
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

    func gotoHomeView(location: CLLocation?) -> Void {
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

    func gotoHomeViewWithNotificationPayload(payload: Dictionary<String, AnyObject>) -> Void {
        if var viewController = self.presentingViewController {
            while viewController.presentingViewController != nil && !viewController.presentingViewController!.isKindOfClass(LoginViewController) {
                viewController = viewController.presentingViewController!
            }

            let homeViewController = viewController as! HomeViewController
            homeViewController.dismissViewControllerAnimated(true, completion: {
                homeViewController.routeNotificationPayload(payload)
            })
        }
    }

    func routeNotificationPayload(payload: Dictionary<String, AnyObject>) -> Void {
        if payload["type"] != nil {
            let type = payload["type"] as! String
            switch type {
            case "postStar", "postComment":
                if payload["pid"] != nil {
                    let pid = payload["pid"] as! String
                    FbaseDataService.ds.getPost(pid, withCompletionBlock: {
                        (post) in
                        if post.value != nil {
                            let postData = self.convertSnapshotToDictionary(post)

                            // Create post object
                            let pid = post.key
                            let uid = postData[FBASE_POST_UID] as! String
                            let imageURL = postData[FBASE_POST_IMAGE_URL] as! String
                            let timestamp = postData[FBASE_POST_TIMESTAMP]?.stringValue

                            // Get user
                            FbaseDataService.ds.getUser(uid, withCompletionBlock: {
                                (user) in
                                if user.value != nil {
                                    let userData = self.convertSnapshotToDictionary(user)

                                    let displayName = userData[FBASE_USER_DISPLAY_NAME] as! String
                                    let profileImageURL = userData[FBASE_USER_PROFILE_IMAGE_URL] as! String

                                    let post = Post(pid: pid, uid: uid, imageURL: imageURL, timestamp: timestamp!, userDisplayName: displayName, userProfileImageURL: profileImageURL, lat: 0.0, lon: 0.0, commentCount: 0, starCount: 0, userStarred: false)

                                    self.performSegueWithIdentifier(SEGUE_POST_DETAIL, sender: post)
                                }
                            })
                        }
                    })
                }
            case "newFollower":
                if payload["uid"] != nil {
                    let uid = payload["uid"] as! String
                    FbaseDataService.ds.getUser(uid, withCompletionBlock: {
                        (user) in
                        if user.value != nil {
                            let userData = self.convertSnapshotToDictionary(user)
                            let user = User(data: userData)
                            self.performSegueWithIdentifier(SEGUE_PERSON, sender: user)
                        }
                    })
                }
            default:
                break
            }
        }
    }

    func handleNotificationPayload(payload: Dictionary<String, AnyObject>) -> Void {
        self.gotoHomeViewWithNotificationPayload(payload)
    }

    func checkPushNotification() -> Void {
        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.Foreground
        readAction.destructive = false
        readAction.authenticationRequired = true

        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.Foreground
        deleteAction.destructive = true
        deleteAction.authenticationRequired = true

        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.Foreground
        ignoreAction.destructive = false
        ignoreAction.authenticationRequired = false

        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], forContext: UIUserNotificationActionContext.Minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], forContext: UIUserNotificationActionContext.Default)

        let types = [.Alert, .Badge, .Sound] as UIUserNotificationType
        let notificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)

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
