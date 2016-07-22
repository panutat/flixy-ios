import Foundation

class User {

    private var _uid: String!
    private var _provider: String!
    private var _token: String!
    private var _email: String!
    private var _id: String!
    private var _displayName: String!
    private var _profileImageURL: String!
    private var _firstName: String!
    private var _lastName: String!
    private var _gender: String!
    private var _link: String!
    private var _timezone: String!
    private var _deviceToken: String!
    private var _endpointArn: String!
    private var _stats: Dictionary<String, Int>!

    var uid: String! {
        get {
            return self._uid
        }
    }

    var provider: String! {
        get {
            return self._provider
        }
    }

    var token: String {
        get {
            return self._token
        }
    }

    var email: String! {
        get {
            return self._email
        }
    }

    var id: String! {
        get {
            return self._id
        }
    }

    var displayName: String! {
        get {
            return self._displayName
        }
        set (displayName) {
            self._displayName = displayName
        }
    }

    var profileImageURL: String! {
        get {
            return self._profileImageURL
        }
        set (profileImageURL) {
            self._profileImageURL = profileImageURL
        }
    }

    var firstName: String! {
        get {
            return self._firstName
        }
        set (firstName) {
            self._firstName = firstName
        }
    }

    var lastName: String! {
        get {
            return self._lastName
        }
        set (lastName) {
            self._lastName = lastName
        }
    }

    var gender: String! {
        get {
            return self._gender
        }
    }

    var link: String! {
        get {
            return self._link
        }
    }

    var timezone: String! {
        get {
            return self._timezone
        }
    }

    var deviceToken: String! {
        get {
            return self._deviceToken
        }
        set (deviceToken) {
            self._deviceToken = deviceToken
        }
    }

    var endpointArn: String! {
        get {
            return self._endpointArn
        }
        set (endpointArn) {
            self._endpointArn = endpointArn
        }
    }

    var stats: Dictionary<String, Int>! {
        get {
            return self._stats
        }
        set (stats) {
            self._stats = stats
        }
    }

    init(data: Dictionary<String, AnyObject>) {
        if let uid = data[FBASE_USER_UID] as! String? {
            self._uid = uid
        }
        if let provider = data[FBASE_USER_PROVIDER] as! String? {
            self._provider = provider
        }
        if let token = data[FBASE_USER_TOKEN] as! String? {
            self._token = token
        }
        if let email = data[FBASE_USER_EMAIL] as! String? {
            self._email = email
        }
        if let id = data[FBASE_USER_FBOOK_ID] as! String? {
            self._id = id
        }
        if let displayName = data[FBASE_USER_DISPLAY_NAME] as! String? {
            self._displayName = displayName
        }
        if let profileImageURL = data[FBASE_USER_PROFILE_IMAGE_URL] as! String? {
            self._profileImageURL = profileImageURL
        }
        if let firstName = data[FBASE_USER_FIRST_NAME] as! String? {
            self._firstName = firstName
        }
        if let lastName = data[FBASE_USER_LAST_NAME] as! String? {
            self._lastName = lastName
        }
        if let gender = data[FBASE_USER_GENDER] as! String? {
            self._gender = gender
        }
        if let link = data[FBASE_USER_LINK] as! String? {
            self._link = link
        }
        if let timezone = data[FBASE_USER_TIMEZONE] as! String? {
            self._timezone = timezone
        }
        if let deviceToken = data[FBASE_USER_DEVICE_TOKEN] as! String? {
            self._deviceToken = deviceToken
        }
        if let endpointArn = data[FBASE_USER_ENDPOINT_ARN] as! String? {
            self._endpointArn = endpointArn
        }
        if let stats = data[FBASE_USER_STATS] as! Dictionary<String, Int>? {
            self._stats = stats
        }
    }

    func convertToDictionary() -> Dictionary<String, AnyObject> {
        return [
            FBASE_USER_UID: "\(self._uid)",
            FBASE_USER_PROVIDER: "\(self._provider)",
            FBASE_USER_TOKEN: "\(self._token)",
            FBASE_USER_EMAIL: "\(self._email)",
            FBASE_USER_DISPLAY_NAME: "\(self._displayName)",
            FBASE_USER_FBOOK_ID: "\(self._id)",
            FBASE_USER_PROFILE_IMAGE_URL: "\(self._profileImageURL)",
            FBASE_USER_FIRST_NAME: "\(self._firstName)",
            FBASE_USER_LAST_NAME: "\(self._lastName)",
            FBASE_USER_GENDER: "\(self._gender)",
            FBASE_USER_LINK: "\(self._link)",
            FBASE_USER_TIMEZONE: "\(self._timezone)",
            FBASE_USER_DEVICE_TOKEN: "\(self._deviceToken)",
            FBASE_USER_ENDPOINT_ARN: "\(self._endpointArn)"
        ]
    }

}
