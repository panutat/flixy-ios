import Foundation
import MapKit

class Post {

    private var _pid: String
    private var _uid: String
    private var _imageURL: String
    private var _timestamp: String
    private var _userDisplayName: String
    private var _userProfileImageURL: String
    private var _lat: CLLocationDegrees
    private var _lon: CLLocationDegrees
    private var _commentCount: Int
    private var _starCount: Int
    private var _userStarred: Bool
    private var _countsLoaded: Bool = false

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

    var imageURL: String {
        get {
            return _imageURL
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

    var lat: CLLocationDegrees {
        get {
            return _lat
        }
    }

    var lon: CLLocationDegrees {
        get {
            return _lon
        }
    }

    var commentCount: Int {
        get {
            return _commentCount
        }
        set (commentCount) {
            _commentCount = commentCount
        }
    }

    var starCount: Int {
        get {
            return _starCount
        }
        set (starCount) {
            _starCount = starCount
        }
    }

    var userStarred: Bool {
        get {
            return _userStarred
        }
        set (userStarred) {
            _userStarred = userStarred
        }
    }

    var countsLoaded: Bool {
        get {
            return _countsLoaded
        }
        set (countsLoaded) {
            _countsLoaded = countsLoaded
        }
    }

    init(pid: String, uid: String, imageURL: String, timestamp: String, userDisplayName: String, userProfileImageURL: String, lat: CLLocationDegrees, lon: CLLocationDegrees, commentCount: Int, starCount: Int, userStarred: Bool) {
        self._pid = pid
        self._uid = uid
        self._imageURL = imageURL
        self._timestamp = timestamp
        self._userDisplayName = userDisplayName
        self._userProfileImageURL = userProfileImageURL
        self._lat = lat
        self._lon = lon
        self._commentCount = commentCount
        self._starCount = starCount
        self._userStarred = userStarred
    }

    func addStarCount(num: Int) -> Void {
        self._starCount = self._starCount + num
    }

    func subtractStarCount(num: Int) -> Void {
        self._starCount = self._starCount - num
        if self._starCount < 0 {
            self._starCount = 0
        }
    }

    func addCommentCount(num: Int) -> Void {
        self._commentCount = self._commentCount + num
    }

    func subtractCommentCount(num: Int) -> Void {
        self._commentCount = self._commentCount - num
        if self._commentCount < 0 {
            self._commentCount = 0
        }
    }

}
