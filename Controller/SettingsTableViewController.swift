import UIKit

class SettingsTableViewController: CommonTableViewController {

    // MARK: @IBOutlet

    // MARK: Local Variables

    var parentView: SettingsViewController!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        self.tableView.backgroundColor = CustomColor.VERY_LIGHT_GRAY
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // Profile clicked
                self.parentView.performSegueWithIdentifier(SEGUE_SETTINGS_PROFILE, sender: self)
            } else if indexPath.row == 1 {
                // Password clicked
                if self.parentView.user.provider != FBASE_PROVIDER_FBOOK {
                    // Not Facebook so allow update
                    self.parentView.performSegueWithIdentifier(SEGUE_SETTINGS_PASSWORD, sender: self)
                } else {
                    // Facebook cannot update password
                    self.parentView.showAlert(ALERT_MESSAGE_TITLE_NOTICE, msg: ALERT_MESSAGE_FACEBOOK_NO_PASSWORD)
                }
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                // Notifications clicked
                self.parentView.performSegueWithIdentifier(SEGUE_SETTINGS_NOTIFICATIONS, sender: self)
            } else if indexPath.row == 1 {
                // Privacy clicked
                self.parentView.performSegueWithIdentifier(SEGUE_SETTINGS_PRIVACY, sender: self)
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                // Logout clicked
                self.parentView.logout()
            }
        }
    }

    // MARK: @IBAction

    // MARK: Helpers

}
