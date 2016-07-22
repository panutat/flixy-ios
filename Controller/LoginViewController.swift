import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import Crashlytics

class LoginViewController: CommonViewController {

    // MARK: @IBOutlet

    @IBOutlet weak var loginEmailField: LoginTextField!
    @IBOutlet weak var loginPasswordField: LoginTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Check for current user
        let currentUser: Dictionary<String, AnyObject> = self.getCurrentUser()
        if currentUser.count > 1 {
            // Check user provider
            let provider = currentUser[FBASE_USER_PROVIDER] as! String
            if (provider == FBASE_PROVIDER_FBOOK) {
                // Facebook user
                if let currentToken = FBSDKAccessToken.currentAccessToken() {
                    // Proceed with authentication
                    self.authenticateFbook(currentToken.tokenString)
                }
            } else if (provider == FBASE_PROVIDER_EMAIL) {
                // Email user
                // Segue to home view
                self.clearForm()

                SpinnerView.show(ALERT_MESSAGE_AUTHENTICATING)
                Delay.run(Delay.Login, withCompletion: {
                    SpinnerView.hide()
                    self.loginUser(currentUser)
                })
            }
        } else {
            // Set last user email if exists
            if let last_email = UserUtil.getlastUserEmail() {
                self.loginEmailField.text = last_email
            }
        }
    }

    func loginUser(user: Dictionary<String, AnyObject>) -> Void {
        // Set Crashlytics user
        Crashlytics.sharedInstance().setUserIdentifier(user[FBASE_USER_UID] as? String)
        Crashlytics.sharedInstance().setUserEmail(user[FBASE_USER_EMAIL] as? String)

        // Update last login timestamp
        FbaseDataService.ds.updateLastLoginTimestamp(user[FBASE_USER_UID] as! String, withCompletionBlock: {
            (error, ref) in
            if error == nil {
                // Load settings or create if it doesn't exist
                FbaseDataService.ds.getSettings(user[FBASE_USER_UID] as! String, withCompletionBlock: {
                    (settings) in
                    if settings.childrenCount == 0 {
                        // Create new with defaults
                        let newSettings: UserSettings = UserSettings()
                        FbaseDataService.ds.createSettings(user[FBASE_USER_UID] as! String, post_comment: newSettings.notificationPostComment, post_star: newSettings.notificationPostStar, new_follower: newSettings.notificationNewFollower, hide_from_people_list: newSettings.privacyHideFromPeopleList, hide_stat_counts: newSettings.privacyHideStatCounts, withCompletionBlock: {
                            (error, ref) in
                            if error == nil {
                                // Load into session and login
                                self.storeUserSettings(newSettings.convertToDictionary())
                                self.performSegueWithIdentifier(SEGUE_LOGIN_SUCCESS, sender: nil)
                            } else {
                                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOGIN_FAILED)
                            }
                        })
                    } else {
                        // Settings exists, load into session and login
                        let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                        self.storeUserSettings(settings_data)
                        self.performSegueWithIdentifier(SEGUE_LOGIN_SUCCESS, sender: nil)
                    }
                })
            } else {
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOGIN_FAILED)
            }
        })
    }

    // MARK: @IBAction

    @IBAction func emailLoginButtonPressed(sender: UIButton) {
        // Check valid fields
        if self.loginEmailField.text != "" && self.loginPasswordField.text != "" && Validation.isValidEmail(self.loginEmailField.text!) {
            // Check for login or create mode
            if self.loginButton.titleLabel?.text == BUTTON_LABEL_CREATE_ACCOUNT {
                SpinnerView.show(ALERT_MESSAGE_CREATING_ACCOUNT)

                // Check if user with email exists
                FbaseDataService.ds.checkUserEmailExists(self.loginEmailField.text!, withCompletionBlock: {
                    (exists) in
                    if !exists {
                        // Doesn't exist so create
                        FbaseDataService.ds.BASE.createUser(self.loginEmailField.text!, password: self.loginPasswordField.text!, withValueCompletionBlock: {
                            (error, result) in
                            SpinnerView.hide()

                            if error != nil {
                                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_CREATE_ACCOUNT_FAILED)
                            } else {
                                self.authenticateEmailPassword(self.loginEmailField.text!, password: self.loginPasswordField.text!)
                            }
                        })
                    } else {
                        SpinnerView.hide()

                        // Email already exists
                        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_EMAIL_ALREADY_EXISTS)
                    }
                })

            } else {
                // Login mode
                self.authenticateEmailPassword(self.loginEmailField.text!, password: self.loginPasswordField.text!)
            }
        } else {
            // Some errors in fields
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_INVALID_FIELDS)
        }
    }

    @IBAction func fbookLoginButtonPressed(sender: UIButton) {
        // Check for Facebook token
        if let currentToken = FBSDKAccessToken.currentAccessToken() {
            // Proceed with authentication
            self.authenticateFbook(currentToken.tokenString)
        } else {
            FBSDKLoginManager().logInWithReadPermissions(FBOOK_PERMISSIONS, fromViewController: self, handler: {
                (fbookResult, fbookError) in
                if fbookError != nil {
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_FBOOK_LOGIN_FAILED)
                } else if fbookResult.isCancelled {
                    // User cancelled Facebook login
                } else if let currentToken = FBSDKAccessToken.currentAccessToken() {
                    // No errors so proceed with authentication
                    self.authenticateFbook(currentToken.tokenString)
                }
            })
        }
    }

    @IBAction func createAccountButtonPressed(sender: UIButton) {
        self.toggleLoginMode()
    }

    @IBAction func forgotPasswordButtonPressed(sender: UIButton) {
        // Test password reset
        FbaseDataService.ds.BASE.resetPasswordForUser(self.loginEmailField.text, withCompletionBlock: {
            (error) in
            if error != nil {
                // Show error message
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_ENTER_VALID_EMAIL)
            } else {
                // Show confirmation
                self.showAlert(ALERT_MESSAGE_TITLE_OK, msg: ALERT_MESSAGE_PASSWORD_RESET_EMAIL_SENT)
            }
        })
    }

    func toggleLoginMode() -> Void {
        if self.createAccountButton.titleLabel?.text == BUTTON_LABEL_CREATE_ACCOUNT {
            self.createAccountButton.setTitle(BUTTON_LABEL_LOGIN, forState: .Normal)
            self.loginButton.setTitle(BUTTON_LABEL_CREATE_ACCOUNT, forState: .Normal)
            self.loginButton.backgroundColor = CustomColor.CREATE_ACCOUNT_BUTTON
        } else {
            self.createAccountButton.setTitle(BUTTON_LABEL_CREATE_ACCOUNT, forState: .Normal)
            self.loginButton.setTitle(BUTTON_LABEL_LOGIN, forState: .Normal)
            self.loginButton.backgroundColor = CustomColor.LOGIN_BUTTON
        }
    }

    func authenticateEmailPassword(email: String, password: String) -> Void {
        SpinnerView.show(ALERT_MESSAGE_AUTHENTICATING)

        FbaseDataService.ds.BASE.authUser(email, password: password, withCompletionBlock: {
            (error, authData) in
            if error != nil {
                SpinnerView.hide()

                // an error occurred while attempting login
                switch(error.code) {
                case FAuthenticationError.UserDoesNotExist.rawValue:
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_USER_DOES_NOT_EXIST)
                    break;
                case FAuthenticationError.InvalidEmail.rawValue:
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_INCORRECT_EMAIL)
                    break;
                case FAuthenticationError.InvalidPassword.rawValue:
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_INCORRECT_PASSWORD)
                    break;
                default:
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_AUTHENTICATION_FAILED)
                    break;
                }
            } else {
                // Check if user already exists
                FbaseDataService.ds.getUser(authData.uid, withCompletionBlock: {
                    (user) in
                    if user.childrenCount == 0 {
                        // User does not exist, create new and store as current user
                        self.createEmailUser(authData, withCompletionBlock: {
                            (local_user) in
                            self.storeCurrentUser(local_user)

                            // Store last user email
                            UserUtil.setLastUserEmail(local_user[FBASE_USER_EMAIL] as! String)

                            // Segue to home view
                            self.clearForm()

                            Delay.run(Delay.Login, withCompletion: {
                                SpinnerView.hide()
                                self.loginUser(local_user)
                            })
                        })
                    } else {
                        // User exists, convert and store as current user
                        let local_user: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(user)
                        self.storeCurrentUser(local_user)

                        // Store last user email
                        UserUtil.setLastUserEmail(local_user[FBASE_USER_EMAIL] as! String)

                        // Segue to home view
                        self.clearForm()
                        Delay.run(Delay.Login, withCompletion: {
                            SpinnerView.hide()
                            self.loginUser(local_user)
                        })
                    }
                })
            }
        })
    }

    func authenticateFbook(accessToken: String) -> Void {
        SpinnerView.show(ALERT_MESSAGE_AUTHENTICATING)

        FbaseDataService.ds.BASE.authWithOAuthProvider(FBASE_PROVIDER_FBOOK, token: accessToken, withCompletionBlock: {
            (error, authData) in
            if error != nil {
                SpinnerView.hide()
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_AUTHENTICATION_FAILED)
            } else {
                // Clear last user email
                UserUtil.clearLastUserEmail()

                // Check if user already exists
                FbaseDataService.ds.getUser(authData.uid, withCompletionBlock: {
                    (user) in
                    if user.childrenCount == 0 {
                        // User does not exist, create new and store as current user
                        self.createFbookUser(authData, withCompletionBlock: {
                            (local_user) in
                            self.storeCurrentUser(local_user)

                            // Segue to home view
                            self.clearForm()
                            Delay.run(Delay.Login, withCompletion: {
                                SpinnerView.hide()
                                self.loginUser(local_user)
                            })
                        })
                    } else {
                        // User exists, convert and store as current user
                        let local_user: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(user)
                        self.storeCurrentUser(local_user)

                        // Segue to home view
                        self.clearForm()
                        Delay.run(Delay.Login, withCompletion: {
                            SpinnerView.hide()
                            self.loginUser(local_user)
                        })
                    }
                })
            }
        })
    }

    func createEmailUser(authData: FAuthData, withCompletionBlock: ((Dictionary<String, AnyObject>) -> Void)!) -> Void {
        // Store user in Firebase
        let provider = authData.providerData

        let user = [
            FBASE_USER_UID: "\(authData.uid)",
            FBASE_USER_PROVIDER: "\(authData.provider)",
            FBASE_USER_TOKEN: "\(authData.token)",
            FBASE_USER_EMAIL: "\(provider[FBASE_PROVIDER_EMAIL_EMAIL]!)",
            FBASE_USER_DISPLAY_NAME: "",
            FBASE_USER_FBOOK_ID: "",
            FBASE_USER_PROFILE_IMAGE_URL: "\(provider[FBASE_PROVIDER_EMAIL_PROFILE_IMAGE_URL]!)",
            FBASE_USER_FIRST_NAME: "",
            FBASE_USER_LAST_NAME: "",
            FBASE_USER_GENDER: "",
            FBASE_USER_LINK: "",
            FBASE_USER_TIMEZONE: "",
            FBASE_USER_DEVICE_TOKEN: "",
            FBASE_USER_ENDPOINT_ARN: ""
        ]
        FbaseDataService.ds.createUser(authData.uid, user: user)

        // Callback call
        withCompletionBlock(user)
    }

    func createFbookUser(authData: FAuthData, withCompletionBlock: ((Dictionary<String, AnyObject>) -> Void)!) -> Void {
        // Store user in Firebase
        let provider = authData.providerData as! Dictionary<String, AnyObject>
        let cachedUserProfile = provider[FBASE_PROVIDER_FBOOK_CACHED_USER_PROFILE] as! Dictionary<String, AnyObject>

        let user = [
            FBASE_USER_UID: "\(authData.uid)",
            FBASE_USER_PROVIDER: "\(authData.provider)",
            FBASE_USER_TOKEN: "\(authData.token)",
            FBASE_USER_EMAIL: "\(provider[FBASE_PROVIDER_FBOOK_EMAIL]!)",
            FBASE_USER_DISPLAY_NAME: "\(provider[FBASE_PROVIDER_FBOOK_DISPLAY_NAME]!)",
            FBASE_USER_FBOOK_ID: "\(provider[FBASE_PROVIDER_FBOOK_ID]!)",
            FBASE_USER_PROFILE_IMAGE_URL: "\(provider[FBASE_PROVIDER_FBOOK_PROFILE_IMAGE_URL]!)",
            FBASE_USER_FIRST_NAME: "\(cachedUserProfile[FBASE_PROVIDER_FBOOK_FIRST_NAME]!)",
            FBASE_USER_LAST_NAME: "\(cachedUserProfile[FBASE_PROVIDER_FBOOK_LAST_NAME]!)",
            FBASE_USER_GENDER: "\(cachedUserProfile[FBASE_PROVIDER_FBOOK_GENDER]!)",
            FBASE_USER_LINK: "\(cachedUserProfile[FBASE_PROVIDER_FBOOK_LINK]!)",
            FBASE_USER_TIMEZONE: "\(cachedUserProfile[FBASE_PROVIDER_FBOOK_TIMEZONE]!)",
            FBASE_USER_DEVICE_TOKEN: "",
            FBASE_USER_ENDPOINT_ARN: ""
        ]
        FbaseDataService.ds.createUser(authData.uid, user: user)

        // Callback call
        withCompletionBlock(user)
    }

    func clearForm() -> Void {
        self.loginEmailField.text = ""
        self.loginPasswordField.text = ""
    }

}
