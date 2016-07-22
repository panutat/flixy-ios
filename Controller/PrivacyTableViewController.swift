import UIKit

class PrivacyTableViewController: CommonTableViewController {

    // MARK: @IBOutlet

    @IBOutlet weak var hideFromPeopleListSwitch: UISwitch!
    @IBOutlet weak var hideStatCountsSwitch: UISwitch!

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

        // Setup switches
        self.setupSwitches()
    }

    // MARK: @IBAction

    @IBAction func hideFromPeopleListSwitchToggled(sender: UISwitch) {
        // Update setting in Firebase
        FbaseDataService.ds.updatePrivacyHideFromPeopleListSetting(self.user.uid, privacyHideFromPeopleList: sender.on) {
            (error, ref) in
            if error == nil {
                // Update settings in session
                self.settings.privacyHideFromPeopleList = sender.on
                UserUtil.setSettings(self.settings)
            } else {
                // Alert and restore
                self.hideFromPeopleListSwitch.setOn(!sender.on, animated: true)
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SETTINGS_UPDATE_FAILED)
            }
        }
    }

    @IBAction func hideStatCountsSwitchToggled(sender: UISwitch) {
        // Update setting in Firebase
        FbaseDataService.ds.updatePrivacyHideStatCountsSetting(self.user.uid, privacyHideStatCounts: sender.on) {
            (error, ref) in
            if error == nil {
                // Update settings in session
                self.settings.privacyHideStatCounts = sender.on
                UserUtil.setSettings(self.settings)
            } else {
                // Alert and restore
                self.hideStatCountsSwitch.setOn(!sender.on, animated: true)
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SETTINGS_UPDATE_FAILED)
            }
        }
    }

    // MARK: Helpers

    func setupSwitches() -> Void {
        // Hide from people list switch
        self.hideFromPeopleListSwitch.setOn(self.settings.privacyHideFromPeopleList, animated: true)

        // Hide stats count switch
        self.hideStatCountsSwitch.setOn(self.settings.privacyHideStatCounts, animated: true)
    }

}
