import Foundation

class UserUtil {

    // MARK: Users

    static func getCurrent() -> User? {
        if let current_user = NSUserDefaults.standardUserDefaults().valueForKey(CURRENT_USER) as! Dictionary<String, AnyObject>? {
            return User(data: current_user)
        } else {
            return nil
        }
    }

    static func setCurrent(user: User) -> Void {
        let userDictionary = user.convertToDictionary() as Dictionary<String, AnyObject>
        NSUserDefaults.standardUserDefaults().setValue(userDictionary, forKey: CURRENT_USER)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    static func setLastUserEmail(email: String) -> Void {
        NSUserDefaults.standardUserDefaults().setValue(email, forKey: LAST_USER_EMAIL)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    static func clearLastUserEmail() -> Void {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(LAST_USER_EMAIL)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    static func getlastUserEmail() -> String? {
        if let email = NSUserDefaults.standardUserDefaults().valueForKey(LAST_USER_EMAIL) {
            return email as? String
        } else {
            return nil
        }
    }

    static func logout() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(CURRENT_USER)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: User Settings

    static func getSettings() -> UserSettings? {
        if let user_settings = NSUserDefaults.standardUserDefaults().valueForKey(USER_SETTINGS) as! Dictionary<String, AnyObject>? {
            return UserSettings(data: user_settings)
        } else {
            return nil
        }
    }

    static func setSettings(settings: UserSettings) -> Void {
        let settingsDictionary = settings.convertToDictionary() as Dictionary<String, AnyObject>
        NSUserDefaults.standardUserDefaults().setValue(settingsDictionary, forKey: USER_SETTINGS)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

}
