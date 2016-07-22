import Foundation

class Comment {

    private var _pcid: String
    private var _pid: String
    private var _uid: String
    private var _message: String
    private var _timestamp: String
    private var _userDisplayName: String
    private var _userProfileImageURL: String

    var pcid: String {
        get {
            return _pcid
        }
    }

    var pid: String {
        get {
            return _pid
        }
    }

    var uid: String {
        get {
            return _uid
        }
    }

    var message: String {
        get {
            return _message
        }
    }

    var timestamp: String {
        get {
            return _timestamp
        }
    }

    var userDisplayName: String {
        get {
            return _userDisplayName
        }
    }

    var userProfileImageURL: String {
        get {
            return _userProfileImageURL
        }
    }

    init(pcid: String, pid: String, uid: String, message: String, timestamp: String, userDisplayName: String, userProfileImageURL: String) {
        self._pcid = pcid
        self._pid = pid
        self._uid = uid
        self._message = message
        self._timestamp = timestamp
        self._userDisplayName = userDisplayName
        self._userProfileImageURL = userProfileImageURL
    }

}
