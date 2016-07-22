import Foundation

class UserSettings {

    private var _notificationPostComment: Bool = true
    private var _notificationPostStar: Bool = true
    private var _notificationNewFollower: Bool = true
    private var _privacyHideFromPeopleList: Bool = false
    private var _privacyHideStatCounts: Bool = false

    var notificationPostComment: Bool {
        get {
            return self._notificationPostComment
        }
        set (notificationPostComment) {
            self._notificationPostComment = notificationPostComment
        }
    }

    var notificationPostStar: Bool {
        get {
            return self._notificationPostStar
        }
        set (notificationPostStar) {
            self._notificationPostStar = notificationPostStar
        }
    }

    var notificationNewFollower: Bool {
        get {
            return self._notificationNewFollower
        }
        set (notificationNewFollower) {
            self._notificationNewFollower = notificationNewFollower
        }
    }

    var privacyHideFromPeopleList: Bool {
        get {
            return self._privacyHideFromPeopleList
        }
        set (privacyHideFromPeopleList) {
            self._privacyHideFromPeopleList = privacyHideFromPeopleList
        }
    }

    var privacyHideStatCounts: Bool {
        get {
            return self._privacyHideStatCounts
        }
        set (privacyHideStatCounts) {
            self._privacyHideStatCounts = privacyHideStatCounts
        }
    }

    init() {

    }

    init(data: Dictionary<String, AnyObject>) {
        if let notificationPostComment = data[FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT] as! Bool? {
            self._notificationPostComment = notificationPostComment
        }
        if let notificationPostStar = data[FBASE_USER_SETTING_NOTIFICATION_POST_STAR] as! Bool? {
            self._notificationPostStar = notificationPostStar
        }
        if let notificationNewFollower = data[FBASE_USER_SETTING_NOTIFICATION_NEW_FOLLOWER] as! Bool? {
            self._notificationNewFollower = notificationNewFollower
        }
        if let privacyHideFromPeopleList = data[FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST] as! Bool? {
            self._privacyHideFromPeopleList = privacyHideFromPeopleList
        }
        if let privacyHideStatCounts = data[FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS] as! Bool? {
            self._privacyHideStatCounts = privacyHideStatCounts
        }
    }

    func convertToDictionary() -> Dictionary<String, AnyObject> {
        return [
            FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT: self._notificationPostComment,
            FBASE_USER_SETTING_NOTIFICATION_POST_STAR: self._notificationPostStar,
            FBASE_USER_SETTING_NOTIFICATION_NEW_FOLLOWER: self._notificationNewFollower,
            FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST: self._privacyHideFromPeopleList,
            FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS: self._privacyHideStatCounts
        ]
    }

}
