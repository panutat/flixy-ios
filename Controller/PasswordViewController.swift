import UIKit

class PasswordViewController: CommonViewController {

    // MARK: @IBOutlet

    @IBOutlet weak var currentPasswordField: StandardTextField!
    @IBOutlet weak var newPasswordField: StandardTextField!
    @IBOutlet weak var confirmPasswordField: StandardTextField!
    @IBOutlet weak var currentPasswordLabel: StandardTextLabel!
    @IBOutlet weak var newPasswordLabel: StandardTextLabel!
    @IBOutlet weak var confirmPasswordLabel: StandardTextLabel!

    // MARK: Local Variables

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func saveButtonPressed(sender: UIBarButtonItem) {
        // Validate fields
        if let currentPassword = self.currentPasswordField.text where !currentPassword.isEmpty {
            if let newPassword = self.newPasswordField.text where !newPassword.isEmpty {
                if let confirmPassword = self.confirmPasswordField.text where !confirmPassword.isEmpty {
                    if newPassword == confirmPassword {
                        SpinnerView.show(ALERT_MESSAGE_PROCESSING)

                        // Send request to Firebase
                        FbaseDataService.ds.updateUserPassword(self.user.uid, email: self.user.email, oldPassword: currentPassword, newPassword: newPassword, withCompletionBlock: {
                            (error) in
                            SpinnerView.hide()

                            if error == nil {
                                // Password updated
                                self.showAlert(ALERT_MESSAGE_TITLE_OK, msg: ALERT_MESSAGE_PASSWORD_UPDATED)
                                self.dismissViewControllerAnimated(true, completion: nil)
                            } else {
                                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_UPDATE_PASSWORD_FAILED)
                            }
                        })
                    } else {
                        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_NEW_CONFIRM_UNMATCHED)
                    }
                } else {
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_CONFIRM_PASSWORD_REQUIRED)
                }
            } else {
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_NEW_PASSWORD_REQUIRED)
            }
        } else {
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_CURRENT_PASSWORD_REQUIRED)
        }
    }

    // MARK: Helpers

}
