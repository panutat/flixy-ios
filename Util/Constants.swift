import Foundation

// NSUserDefaults Constants
let CURRENT_USER: String = "current_user"
let USER_SETTINGS: String = "user_settings"
let LAST_USER_EMAIL: String = "last_user_email"

// Table Cell Identifier Constants
let CELL_IDENTIFIER_POST: String = "postCell"
let CELL_IDENTIFIER_COMMENT: String = "commentCell"
let CELL_IDENTIFIER_POST_PHOTO: String = "postPhotoCell"
let CELL_IDENTIFIER_PERSON: String = "personCell"
let CELL_IDENTIFIER_RANK: String = "rankingCell"

// Fbase Constants
let FBASE_ROOT_URL: String = "https://www.firebaseio.com"

let FBASE_USER_UID: String = "uid"
let FBASE_USER_PROVIDER: String = "provider"
let FBASE_USER_TOKEN: String = "token"
let FBASE_USER_EMAIL: String = "email"
let FBASE_USER_DISPLAY_NAME: String = "displayName"
let FBASE_USER_FBOOK_ID: String = "id"
let FBASE_USER_PROFILE_IMAGE_URL: String = "profileImageURL"
let FBASE_USER_FIRST_NAME: String = "first_name"
let FBASE_USER_LAST_NAME: String = "last_name"
let FBASE_USER_GENDER: String = "gender"
let FBASE_USER_LINK: String = "link"
let FBASE_USER_TIMEZONE: String = "timezone"
let FBASE_USER_LAST_LOGIN_TIMESTAMP: String = "lastLoginTimestamp"
let FBASE_USER_DEVICE_TOKEN: String = "deviceToken"
let FBASE_USER_ENDPOINT_ARN: String = "endpointArn"

let FBASE_USER_STATS: String = "stats"

let FBASE_USER_FOLLOWER_TIMESTAMP: String = "timestamp"
let FBASE_USER_FOLLOWING_TIMESTAMP: String = "timestamp"

let FBASE_USER_STAT_POST_COUNT: String = "postCount"
let FBASE_USER_STAT_STAR_COUNT: String = "starCount"

let FBASE_USER_SETTING_UID: String = "uid"
let FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT: String = "notificationPostComment"
let FBASE_USER_SETTING_NOTIFICATION_POST_STAR: String = "notificationPostStar"
let FBASE_USER_SETTING_NOTIFICATION_NEW_FOLLOWER: String = "notificationNewFollower"
let FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST: String = "privacyHideFromPeopleList"
let FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS: String = "privacyHideStatCounts"

let FBASE_POST_PID: String = "pid"
let FBASE_POST_UID: String = "uid"
let FBASE_POST_IMAGE_URL: String = "imageURL"
let FBASE_POST_TIMESTAMP: String = "timestamp"

let FBASE_POST_FLAG_PFID: String = "pfid"
let FBASE_POST_FLAG_PID: String = "pid"
let FBASE_POST_FLAG_UID: String = "uid"
let FBASE_POST_FLAG_TIMESTAMP: String = "timestamp"

let FBASE_POST_STAR_PSID: String = "psid"
let FBASE_POST_STAR_PID: String = "pid"
let FBASE_POST_STAR_UID: String = "uid"
let FBASE_POST_STAR_TIMESTAMP: String = "timestamp"

let FBASE_POST_COMMENT_PCID: String = "pcid"
let FBASE_POST_COMMENT_PID: String = "pid"
let FBASE_POST_COMMENT_UID: String = "uid"
let FBASE_POST_COMMENT_MESSAGE: String = "message"
let FBASE_POST_COMMENT_TIMESTAMP: String = "timestamp"

let FBASE_PROVIDER_FBOOK: String = "facebook"
let FBASE_PROVIDER_FBOOK_CACHED_USER_PROFILE: String = "cachedUserProfile"
let FBASE_PROVIDER_FBOOK_EMAIL: String = "email"
let FBASE_PROVIDER_FBOOK_DISPLAY_NAME: String = "displayName"
let FBASE_PROVIDER_FBOOK_ID: String = "id"
let FBASE_PROVIDER_FBOOK_PROFILE_IMAGE_URL: String = "profileImageURL"
let FBASE_PROVIDER_FBOOK_FIRST_NAME: String = "first_name"
let FBASE_PROVIDER_FBOOK_LAST_NAME: String = "last_name"
let FBASE_PROVIDER_FBOOK_GENDER: String = "gender"
let FBASE_PROVIDER_FBOOK_LINK: String = "link"
let FBASE_PROVIDER_FBOOK_TIMEZONE: String = "timezone"

let FBASE_PROVIDER_EMAIL: String = "password"
let FBASE_PROVIDER_EMAIL_EMAIL: String = "email"
let FBASE_PROVIDER_EMAIL_PROFILE_IMAGE_URL: String = "profileImageURL"

// FBOOK Constants
let FBOOK_PERMISSIONS: [String] = ["public_profile", "user_friends", "email"]

// Segue Constants
let SEGUE_LOGIN_SUCCESS: String = "loginSuccessSegue"
let SEGUE_CAMERA: String = "cameraSegue"
let SEGUE_RANKING: String = "rankingSegue"
let SEGUE_PEOPLE: String = "peopleSegue"
let SEGUE_TIMELINE: String = "timelineSegue"
let SEGUE_POST_DETAIL: String = "postDetailSegue"
let SEGUE_POST_DETAIL_MAP: String = "postDetailMapSegue"
let SEGUE_PERSON: String = "personSegue"
let SEGUE_SETTINGS: String = "settingsSegue"
let SEGUE_SETTINGS_PROFILE: String = "profileSegue"
let SEGUE_SETTINGS_PASSWORD: String = "passwordSegue"
let SEGUE_SETTINGS_NOTIFICATIONS: String = "notificationsSegue"
let SEGUE_SETTINGS_PRIVACY: String = "privacySegue"
let SEGUE_SETTINGS_EMBED: String = "embedSegue"

// Alert Message Constants
let ALERT_MESSAGE_TITLE_ERROR: String = "Error"
let ALERT_MESSAGE_TITLE_OK: String = "OK"
let ALERT_MESSAGE_TITLE_NOTICE: String = "Notice"
let ALERT_MESSAGE_TITLE_CONFIRM: String = "Confirm"
let ALERT_MESSAGE_BUTTON_CANCEL: String = "Cancel"
let ALERT_MESSAGE_AUTHENTICATING: String = "Authenticating"
let ALERT_MESSAGE_CREATING_ACCOUNT: String = "Creating account"
let ALERT_MESSAGE_LOGIN_FAILED: String = "Login failed"
let ALERT_MESSAGE_FBOOK_LOGIN_FAILED: String = "Facebook login failed"
let ALERT_MESSAGE_AUTHENTICATION_FAILED: String = "Authentication failed"
let ALERT_MESSAGE_INCORRECT_PASSWORD: String = "Incorrect password"
let ALERT_MESSAGE_INCORRECT_EMAIL: String = "Incorrect e-mail"
let ALERT_MESSAGE_USER_DOES_NOT_EXIST: String = "User does not exist"
let ALERT_MESSAGE_CREATE_ACCOUNT_FAILED: String = "Create account failed"
let ALERT_MESSAGE_INVALID_FIELDS: String = "Invalid field values"
let ALERT_MESSAGE_LOCATION_SERVICE_DISABLED: String = "Location service disabled"
let ALERT_MESSAGE_LOCATION_UNAVAILABLE: String = "Location unavailable"
let ALERT_MESSAGE_CAMERA_UNAVAILABLE: String = "Camera not available"
let ALERT_MESSAGE_IMAGE_UPLOAD_FAILED: String = "Image upload failed"
let ALERT_MESSAGE_SAVING_IMAGE: String = "Saving image"
let ALERT_MESSAGE_POST_FAILED: String = "Post failed"
let ALERT_MESSAGE_INVALID_LOCATION: String = "Invalid location"
let ALERT_MESSAGE_SAVE_LOCATION_FAILED: String = "Save location failed"
let ALERT_MESSAGE_SAVE_PROFILE_FAILED: String = "Save profile failed"
let ALERT_MESSAGE_ENTER_VALID_EMAIL: String = "Please enter a valid e-mail address"
let ALERT_MESSAGE_PASSWORD_RESET_EMAIL_SENT: String = "Password reset email sent"
let ALERT_MESSAGE_CURRENT_PASSWORD_REQUIRED: String = "Current password required"
let ALERT_MESSAGE_NEW_PASSWORD_REQUIRED: String = "New password required"
let ALERT_MESSAGE_CONFIRM_PASSWORD_REQUIRED: String = "Confirm password required"
let ALERT_MESSAGE_NEW_CONFIRM_UNMATCHED: String = "New and confirm password does not match"
let ALERT_MESSAGE_UPDATE_PASSWORD_FAILED: String = "Password update failed"
let ALERT_MESSAGE_PASSWORD_UPDATED: String = "Password updated"
let ALERT_MESSAGE_PROCESSING: String = "Processing"
let ALERT_MESSAGE_FACEBOOK_NO_PASSWORD: String = "Passwords are not required for Facebook login"
let ALERT_MESSAGE_EMAIL_ALREADY_EXISTS: String = "Account with that e-mail already exists"
let ALERT_MESSAGE_FACEBOOK_POST_FAILED: String = "Post could not be shared at this time"
let ALERT_MESSAGE_FACEBOOK_POST_SUCCESS: String = "Post shared successfully"
let ALERT_MESSAGE_INVALID_COMMENT: String = "Please enter a valid comment"
let ALERT_MESSAGE_COMMENT_SEND_FAILED: String = "Send comment failed"
let ALERT_MESSAGE_NETWORK_UNAVAILABLE: String = "Network connection unavailable"
let ALERT_MESSAGE_CONFIRM_DELETE_POST: String = "Are you sure you want to delete this post?"
let ALERT_MESSAGE_CONFIRM_DELETE_COMMENT: String = "Are you sure you want to delete this comment?"
let ALERT_MESSAGE_LOCATION_NOT_FOUND: String = "Location not found"
let ALERT_MESSAGE_LOCATION_MISSING_CRITERIA: String = "Please enter a search criteria"
let ALERT_MESSAGE_FOLLOW_FAILED: String = "Unable to follow user"
let ALERT_MESSAGE_UNFOLLOW_FAILED: String = "Unable to unfollow user"
let ALERT_MESSAGE_POST_LOCATION_NOT_FOUND: String = "Post location not found"
let ALERT_MESSAGE_SETTINGS_UPDATE_FAILED: String = "Setting update failed"
let ALERT_MESSAGE_CONFIRM_POST_FLAG: String = "Are you sure you want to flag this post as inappropriate?"

// Button Label Constants
let BUTTON_LABEL_CREATE_ACCOUNT: String = "Create Account"
let BUTTON_LABEL_LOGIN: String = "Account Login"
let BUTTON_LABEL_CANCEL: String = "Cancel"
let BUTTON_LABEL_RETAKE: String = "Retake"

// Map Constants
let MAP_OFFSET_LAT: Double = 0.0008
let MAP_OFFSET_LON: Double = 0.001
let MAP_RADIUS: Double = 1000
let MAP_DOUBLE_EPSILON: Double = 0.0001
let MAP_MAX_ALTITUDE: Double = 9000
let MAP_MIN_ALTITUDE: Double = 2000
let MAP_GRID_WIDTH: Int = 60
let MAP_GRID_HEIGHT: Int = 80
let MAP_METERS_PER_DEGREE: Double = 111000

// Amazon AWS S3 Constants
let AWS_COGNITO_REGION_TYPE = AWSRegionType.USEast1  // e.g. AWSRegionType.USEast1
let AWS_DEFAULT_SERVICE_REGION_TYPE = AWSRegionType.USEast1 // e.g. AWSRegionType.USEast1
let AWS_COGNITO_IDENTITY_POOL_ID: String = "us-east-1:xxxxxxxxxxxxxxxxxxxx"
let AWS_S3_WEB_URL: String = "https://s3.amazonaws.com"
let AWS_S3_BUCKET_NAME: String = "xxxxxxxxxxxxx"
let AWS_S3_BUCKET_PREFIX: String = "xxxxxxxxxx"
let AWS_S3_BUCKET_POSTS: String = "xxxxxxxxxxx"
let AWS_S3_BUCKET_USERS: String = "xxxxxxxxxx"
let AWS_SS_CONTENT_TYPE_PNG: String = "image/png"
let AWS_S3_CONTENT_TYPE_JPEG: String = "image/jpeg"
let AWS_S3_UPLOAD_TEMP_FOLDER: String = "xxxxxxxxxxxx"
let AWS_S3_UPLOAD_TEMP_JPEG_EXT: String = ".jpg"

// Image Constants
let IMAGE_AMAZON_S3_COMPRESSION: CGFloat = 0.6
let IMAGE_AMAZON_S3_WIDTH: CGFloat = 800.0
let IMAGE_AMAZON_S3_HEIGHT: CGFloat = 800.0

// Bar Button Label Constants
let BAR_BUTTON_FOLLOW: String = "Follow"
let BAR_BUTTON_UNFOLLOW: String = "Unfollow"

// Ranking list limit
let RANKING_LIST_LIMIT: UInt = 20

// People Filter Type
enum PeopleFilterType: Int {
    case Everyone = 1
    case Followers = 2
    case Following = 3
}
