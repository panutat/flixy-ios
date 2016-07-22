import UIKit

class ProfileViewController: CommonViewController, UITextFieldDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var firstNameField: StandardTextField!
    @IBOutlet weak var lastNameField: StandardTextField!
    @IBOutlet weak var displayNameField: StandardTextField!

    // MARK: Local Variables

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Set field values to current user
        self.initFormFields()
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func saveButtonPressed(sender: UIBarButtonItem) {
        if let user = UserUtil.getCurrent() {
            // Update user object
            user.firstName = self.firstNameField.text
            user.lastName = self.lastNameField.text
            user.displayName = self.displayNameField.text

            SpinnerView.show(ALERT_MESSAGE_PROCESSING)

            // Update firebase
            FbaseDataService.ds.updateUserProfile(user.uid, user: user, withCompletionBlock: {
                (error, ref) in
                SpinnerView.hide()

                if error != nil {
                    // Update failed
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SAVE_PROFILE_FAILED)
                } else {
                    // Save to session
                    UserUtil.setCurrent(user)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        }
    }

    // MARK: Helpers

    func initFormFields() -> Void {
        if let user = UserUtil.getCurrent() {
            self.firstNameField.text = user.firstName
            self.lastNameField.text = user.lastName
            self.displayNameField.text = user.displayName
        }
    }

}
