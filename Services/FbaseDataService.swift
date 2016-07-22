import Foundation
import Firebase
import MapKit

class FbaseDataService {

    static let ds = FbaseDataService()

    private var _BASE = Firebase(url: "\(FBASE_ROOT_URL)")
    private var _USERS = Firebase(url: "\(FBASE_ROOT_URL)/users")
    private var _USER_FOLLOWERS = Firebase(url: "\(FBASE_ROOT_URL)/user_followers")
    private var _USER_FOLLOWINGS = Firebase(url: "\(FBASE_ROOT_URL)/user_followings")
    private var _USER_STATS = Firebase(url: "\(FBASE_ROOT_URL)/user_stats")
    private var _USER_SETTINGS = Firebase(url: "\(FBASE_ROOT_URL)/user_settings")
    private var _POSTS = Firebase(url: "\(FBASE_ROOT_URL)/posts")
    private var _POST_STARS = Firebase(url: "\(FBASE_ROOT_URL)/post_stars")
    private var _POST_FLAGS = Firebase(url: "\(FBASE_ROOT_URL)/post_flags")
    private var _POST_COMMENTS = Firebase(url: "\(FBASE_ROOT_URL)/post_comments")

    var BASE: Firebase {
        return _BASE
    }

    var USERS: Firebase {
        return _USERS
    }

    var USER_FOLLOWERS: Firebase {
        return _USER_FOLLOWERS
    }

    var USER_FOLLOWINGS: Firebase {
        return _USER_FOLLOWINGS
    }

    var USER_STATS: Firebase {
        return _USER_STATS
    }

    var USER_SETTINGS: Firebase {
        return _USER_SETTINGS
    }

    var POSTS: Firebase {
        return _POSTS
    }

    var POST_STARS: Firebase {
        return _POST_STARS
    }

    var POST_FLAGS: Firebase {
        return _POST_FLAGS
    }

    var POST_COMMENTS: Firebase {
        return _POST_COMMENTS
    }

    // MARK: Users Methods

    func logout() -> Void {
        self.BASE.unauth()
    }

    func createUser(uid: String, user: Dictionary<String, AnyObject>) -> Void {
        self.USERS.childByAppendingPath(uid).setValue(user)
    }

    func getUser(uid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USERS.childByAppendingPath(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func getUsers(withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USERS.observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func checkUserEmailExists(email: String, withCompletionBlock: ((Bool) -> Void)!) {
        self.USERS.queryOrderedByChild(FBASE_USER_EMAIL).queryEqualToValue(email).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            if snapshot.childrenCount > 0 {
                withCompletionBlock(true)
            } else {
                withCompletionBlock(false)
            }
        })
    }

    func updateUserProfileImage(uid: String, profileImageURL: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues([FBASE_USER_PROFILE_IMAGE_URL: profileImageURL]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateUserDeviceTokenAndEndpointArn(uid: String, deviceToken: String, endpointArn: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues([FBASE_USER_DEVICE_TOKEN: deviceToken, FBASE_USER_ENDPOINT_ARN: endpointArn]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateUserDeviceToken(uid: String, deviceToken: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues([FBASE_USER_DEVICE_TOKEN: deviceToken]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateUserEndpointArn(uid: String, endpointArn: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues([FBASE_USER_ENDPOINT_ARN: endpointArn]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateLastLoginTimestamp(uid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues([FBASE_USER_LAST_LOGIN_TIMESTAMP: FirebaseServerValue.timestamp()]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateUserProfile(uid: String, user: User, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USERS.childByAppendingPath(uid).updateChildValues(user.convertToDictionary()) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateUserPassword(uid: String, email: String, oldPassword: String, newPassword: String, withCompletionBlock: ((NSError?) -> Void)!) {
        self.USERS.childByAppendingPath(uid).changePasswordForUser(email, fromOld: oldPassword, toNew: newPassword, withCompletionBlock: {
            (error) in
            withCompletionBlock(error)
        })
    }

    // MARK: User Followers Methods

    func createUserFollower(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_FOLLOWERS.childByAppendingPath(uid).childByAppendingPath(fid).setValue([FBASE_USER_FOLLOWER_TIMESTAMP: FirebaseServerValue.timestamp()], withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref)
        })
    }

    func getUserFollowers(uid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_FOLLOWERS.childByAppendingPath(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func getUserFollower(uid: String, fid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_FOLLOWERS.childByAppendingPath(uid).childByAppendingPath(fid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func deleteUserFollower(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.getUserFollower(uid, fid: fid, withCompletionBlock: {
            (snapshot) in
            for child in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(child.key)
                childSnapshot.ref.removeValue()
            }
            withCompletionBlock(nil, snapshot.ref)
        })
    }

    // MARK: User Followings Methods

    func createUserFollowing(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_FOLLOWINGS.childByAppendingPath(uid).childByAppendingPath(fid).setValue([FBASE_USER_FOLLOWING_TIMESTAMP: FirebaseServerValue.timestamp()], withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref)
        })
    }

    func getUserFollowings(uid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_FOLLOWINGS.childByAppendingPath(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func getUserFollowing(uid: String, fid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_FOLLOWINGS.childByAppendingPath(uid).childByAppendingPath(fid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func deleteUserFollowing(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.getUserFollowing(uid, fid: fid, withCompletionBlock: {
            (snapshot) in
            for child in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(child.key)
                childSnapshot.ref.removeValue()
            }
            withCompletionBlock(nil, snapshot.ref)
        })
    }

    // MARK: User Followers Compound Methods

    func createFollow(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.createUserFollower(uid, fid: fid, withCompletionBlock: {
            (error, ref) in
            if error == nil {
                self.createUserFollowing(fid, fid: uid, withCompletionBlock: {
                    (error, ref) in
                    if error == nil {
                        withCompletionBlock(error, ref)
                    }
                })
            }
        })
    }

    func deleteFollow(uid: String, fid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.deleteUserFollower(uid, fid: fid, withCompletionBlock: {
            (error, ref) in
            if error == nil {
                self.deleteUserFollowing(fid, fid: uid, withCompletionBlock: {
                    (error, ref) in
                    if error == nil {
                        withCompletionBlock(error, ref)
                    }
                })
            }
        })
    }

    // MARK: Posts Methods

    func createPost(uid: String, imageURL: String, withCompletionBlock: ((NSError?, String) -> Void)!) {
        self.POSTS.childByAutoId().setValue([FBASE_POST_UID: uid, FBASE_POST_IMAGE_URL: imageURL, FBASE_POST_TIMESTAMP: FirebaseServerValue.timestamp()], withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref.key)
        })
    }

    func getPost(pid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.POSTS.childByAppendingPath(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func getUserPosts(uid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.POSTS.queryOrderedByChild(FBASE_POST_UID).queryEqualToValue(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func getUserPostCount(uid: String, withCompletionBlock: ((Int) -> Void)!) {
        self.POSTS.queryOrderedByChild(FBASE_POST_UID).queryEqualToValue(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(Int(snapshot.childrenCount))
        })
    }

    // MARK: Post Flags Methods

    func checkPostUserFlag(pid: String, uid: String, withCompletionBlock: ((Bool) -> Void)!) {
        self.POST_FLAGS.queryOrderedByChild(FBASE_POST_FLAG_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            var found = false
            // Find post with matching uid and remove
            for child in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(child.key)
                if childSnapshot.value[FBASE_POST_FLAG_UID] == uid {
                    found = true
                }
            }
            withCompletionBlock(found)
        })
    }

    func createPostFlag(pid: String, uid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        let postFlagData = [
            FBASE_POST_FLAG_PID: pid,
            FBASE_POST_FLAG_UID: uid,
            FBASE_POST_FLAG_TIMESTAMP: FirebaseServerValue.timestamp()
        ]
        self.POST_FLAGS.childByAutoId().setValue(postFlagData, withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref)
        })
    }

    // MARK: Post Stars Methods

    func getPostStars(pid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.POST_STARS.queryOrderedByChild(FBASE_POST_STAR_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func createPostStar(pid: String, uid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        let postStarData = [
            FBASE_POST_STAR_PID: pid,
            FBASE_POST_STAR_UID: uid,
            FBASE_POST_STAR_TIMESTAMP: FirebaseServerValue.timestamp()
        ]
        self.POST_STARS.childByAutoId().setValue(postStarData, withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref)
        })
    }

    func deletePostStar(pid: String, uid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.POST_STARS.queryOrderedByChild(FBASE_POST_STAR_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            // Find post with matching uid and remove
            for child in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(child.key)
                if childSnapshot.value[FBASE_POST_STAR_UID] == uid {
                    childSnapshot.ref.removeValue()
                }
            }
            withCompletionBlock(nil, snapshot.ref)
        })
    }

    func checkPostUserStar(pid: String, uid: String, withCompletionBlock: ((Bool) -> Void)!) {
        self.POST_STARS.queryOrderedByChild(FBASE_POST_STAR_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            var found = false
            // Find post with matching uid and remove
            for child in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(child.key)
                if childSnapshot.value[FBASE_POST_STAR_UID] == uid {
                    found = true
                }
            }
            withCompletionBlock(found)
        })
    }

    func getPostStarCount(pid: String, withCompletionBlock: ((Int) -> Void)!) {
        self.POST_STARS.queryOrderedByChild(FBASE_POST_STAR_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(Int(snapshot.childrenCount))
        })
    }

    // MARK: Post Comments Methods

    func getPostComments(pid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.POST_COMMENTS.queryOrderedByChild(FBASE_POST_COMMENT_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func createPostComment(pid: String, uid: String, message: String, withCompletionBlock: ((NSError?, Firebase, String) -> Void)!) {
        let commentData = [
            FBASE_POST_COMMENT_PID: pid,
            FBASE_POST_COMMENT_UID: uid,
            FBASE_POST_COMMENT_MESSAGE: message,
            FBASE_POST_COMMENT_TIMESTAMP: FirebaseServerValue.timestamp()
        ]
        self.POST_COMMENTS.childByAutoId().setValue(commentData, withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref, ref.key)
        })
    }

    func deletePostComment(pcid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.POST_COMMENTS.childByAppendingPath(pcid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            snapshot.ref.removeValue()
            withCompletionBlock(nil, snapshot.ref)
        })
    }

    func getPostCommentCount(pid: String, withCompletionBlock: ((Int) -> Void)!) {
        self.POST_COMMENTS.queryOrderedByChild(FBASE_POST_COMMENT_PID).queryEqualToValue(pid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(Int(snapshot.childrenCount))
        })
    }

    // MARK: Post Compound Method

    func deletePostCascade(pid: String, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        // Find all post comments and delete
        self.getPostComments(pid, withCompletionBlock: {
            (snapshot) in
            for comment in snapshot.children {
                let childSnapshot = snapshot.childSnapshotForPath(comment.key)
                childSnapshot.ref.removeValue()
            }

            // Find all post stars and delete
            self.getPostStars(pid, withCompletionBlock: {
                (snapshot) in
                for star in snapshot.children {
                    let childSnapshot = snapshot.childSnapshotForPath(star.key)
                    childSnapshot.ref.removeValue()
                }

                // Find and delete post
                self.getPost(pid, withCompletionBlock: {
                    (snapshot) in
                    snapshot.ref.removeValue()

                    withCompletionBlock(nil, snapshot.ref)
                })
            })
        })
    }

    // MARK: User Stats Methods

    func getUserStats(withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_STATS.queryOrderedByChild(FBASE_USER_STAT_POST_COUNT).queryLimitedToLast(RANKING_LIST_LIMIT).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }
    func updateUserPostCount(uid: String, count: Int, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_STATS.childByAppendingPath(uid).updateChildValues([FBASE_USER_STAT_POST_COUNT: count]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func getUserStarCount(uid: String, withCompletionBlock: ((Int) -> Void)!) {
        self.USER_STATS.childByAppendingPath(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            if snapshot.value != nil {
                let stats = snapshot.value as! Dictionary<String, AnyObject>
                if stats[FBASE_USER_STAT_STAR_COUNT] != nil {
                    withCompletionBlock(Int(stats[FBASE_USER_STAT_STAR_COUNT] as! String)!)
                }
            }

            withCompletionBlock(0)
        })
    }

    func updateUserStarCount(uid: String, count: Int, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_STATS.childByAppendingPath(uid).updateChildValues([FBASE_USER_STAT_STAR_COUNT: count]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    // MARK: User Settings

    func createSettings(uid: String, post_comment: Bool, post_star: Bool, new_follower: Bool, hide_from_people_list: Bool, hide_stat_counts: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        let settings = [
            FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT: post_comment,
            FBASE_USER_SETTING_NOTIFICATION_POST_STAR: post_star,
            FBASE_USER_SETTING_NOTIFICATION_NEW_FOLLOWER: new_follower,
            FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST: hide_from_people_list,
            FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS: hide_stat_counts
        ]
        self.USER_SETTINGS.childByAppendingPath(uid).setValue(settings, withCompletionBlock: {
            (error, ref) in
            withCompletionBlock(error, ref)
        })
    }

    func getSettings(uid: String, withCompletionBlock: ((FDataSnapshot) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).observeSingleEventOfType(.Value, withBlock: {
            (snapshot) in
            withCompletionBlock(snapshot)
        })
    }

    func updatePrivacyHideFromPeopleListSetting(uid: String, privacyHideFromPeopleList: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).updateChildValues([FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST: privacyHideFromPeopleList]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updatePrivacyHideStatCountsSetting(uid: String, privacyHideStatCounts: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).updateChildValues([FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS: privacyHideStatCounts]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateNotificationPostCommentSetting(uid: String, notificationPostComment: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).updateChildValues([FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT: notificationPostComment]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateNotificationPostStarSetting(uid: String, notificationPostStar: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).updateChildValues([FBASE_USER_SETTING_NOTIFICATION_POST_STAR: notificationPostStar]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

    func updateNotificationNewFollowerSetting(uid: String, notificationNewFollower: Bool, withCompletionBlock: ((NSError?, Firebase) -> Void)!) {
        self.USER_SETTINGS.childByAppendingPath(uid).updateChildValues([FBASE_USER_SETTING_NOTIFICATION_NEW_FOLLOWER: notificationNewFollower]) {
            (error, ref) in
            withCompletionBlock(error, ref)
        }
    }

}
