import UIKit

class NotificationsTableViewController: CommonTableViewController {

    // MARK: @IBOutlet

    @IBOutlet weak var postCommentsSwitch: UISwitch!
    @IBOutlet weak var postStarsSwitch: UISwitch!
    @IBOutlet weak var newFollowersSwitch: UISwitch!

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

    @IBAction func postCommentsSwitchToggled(sender: UISwitch) {
        // Update setting in Firebase
        FbaseDataService.ds.updateNotificationPostCommentSetting(self.user.uid, notificationPostComment: sender.on) {
            (error, ref) in
            if error == nil {
                // Update settings in session
                self.settings.notificationPostComment = sender.on
                UserUtil.setSettings(self.settings)
            } else {
                // Alert and restore
                self.postCommentsSwitch.setOn(!sender.on, animated: true)
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SETTINGS_UPDATE_FAILED)
            }
        }
    }

    @IBAction func postStarsSwitchToggled(sender: UISwitch) {
        // Update setting in Firebase
        FbaseDataService.ds.updateNotificationPostStarSetting(self.user.uid, notificationPostStar: sender.on) {
            (error, ref) in
            if error == nil {
                // Update settings in session
                self.settings.notificationPostStar = sender.on
                UserUtil.setSettings(self.settings)
            } else {
                // Alert and restore
                self.postStarsSwitch.setOn(!sender.on, animated: true)
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SETTINGS_UPDATE_FAILED)
            }
        }
    }

    @IBAction func newFollowersSwitchToggled(sender: UISwitch) {
        // Update setting in Firebase
        FbaseDataService.ds.updateNotificationNewFollowerSetting(self.user.uid, notificationNewFollower: sender.on) {
            (error, ref) in
            if error == nil {
                // Update settings in session
                self.settings.notificationNewFollower = sender.on
                UserUtil.setSettings(self.settings)
            } else {
                // Alert and restore
                self.newFollowersSwitch.setOn(!sender.on, animated: true)
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_SETTINGS_UPDATE_FAILED)
            }
        }
    }

    // MARK: Helpers

    func setupSwitches() -> Void {
        // Post comments switch
        self.postCommentsSwitch.setOn(self.settings.notificationPostComment, animated: true)

        // Post stars switch
        self.postStarsSwitch.setOn(self.settings.notificationPostStar, animated: true)

        // New followers switch
        self.newFollowersSwitch.setOn(self.settings.notificationNewFollower, animated: true)
    }

}
