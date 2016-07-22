import UIKit
import MobileCoreServices
import Firebase

class SettingsViewController: CommonViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var starsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!

    // MARK: Local Variables

    var embeddedViewController: SettingsTableViewController!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Setup taps
        self.setupTapHandlers()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Load user data in form
        if let profileImageURL = NSURL(string: self.user.profileImageURL) {
            self.profileImage.hnk_setImageFromURL(profileImageURL)
        }

        // Load posts count
        self.loadPostCount()

        // Load likes count
        self.loadLikeCount()

        // Load follower count
        self.loadFollowerCount()

        // Load following count
        self.loadFollowingCount()

        // Animated profile image
        let circleWidth = self.profileImage.bounds.width
        let circleHeight = circleWidth
        let animatedCircleView = AnimatedCircleView(frame: CGRectMake(0, 0, circleWidth, circleHeight))
        self.profileImage.addSubview(animatedCircleView)
        animatedCircleView.animateCircle(1.0)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? SettingsTableViewController where segue.identifier == SEGUE_SETTINGS_EMBED {
            self.embeddedViewController = vc
            vc.parentView = self
        }
    }

    // MARK: @IBAction

    @IBAction func profileImagePressed(sender: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            // Load camera
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            self.presentViewController(imagePicker, animated: true, completion: nil)
        } else {
            // Camera not available
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_CAMERA_UNAVAILABLE)
        }
    }

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // Check for valid image selection
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            // Activate spinner
            SpinnerView.show(ALERT_MESSAGE_SAVING_IMAGE)

            // Upload to AWS
            AWSS3Service.uploadPostImage(pickedImage, withCompletionBlock: {
                (task, request) in
                if let _ = task.error {
                    // Failed
                    SpinnerView.hide()
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_IMAGE_UPLOAD_FAILED)
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    // Build image URL
                    let profileImageURL = "\(AWS_S3_WEB_URL)/\(request.bucket!)/\(request.key!)"

                    // Update user data in Firebase
                    FbaseDataService.ds.updateUserProfileImage(self.user.uid, profileImageURL: profileImageURL, withCompletionBlock: {
                        (error, ref) in
                        if error != nil {
                            // Upload failed
                            SpinnerView.hide()
                            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_IMAGE_UPLOAD_FAILED)
                            self.dismissViewControllerAnimated(true, completion: nil)
                        } else {
                            // Upload success
                            SpinnerView.hide()
                            self.profileImage.image = pickedImage

                            // Update user in session
                            self.user.profileImageURL = profileImageURL
                            UserUtil.setCurrent(self.user)
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    })
                }
            })
        }
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Helpers

    func setupTapHandlers() -> Void {
        // Posts count
        let postsTap = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.handlePostsTap(_:)))
        postsTap.cancelsTouchesInView = false
        postsTap.numberOfTapsRequired = 1
        self.postsCountLabel.addGestureRecognizer(postsTap)

        // Followers count
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.handleFollowersTap(_:)))
        followersTap.cancelsTouchesInView = false
        followersTap.numberOfTapsRequired = 1
        self.followersCountLabel.addGestureRecognizer(followersTap)

        // Following count
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.handleFollowingTap(_:)))
        followingTap.cancelsTouchesInView = false
        followingTap.numberOfTapsRequired = 1
        self.followingCountLabel.addGestureRecognizer(followingTap)
    }

    func handlePostsTap(gesture: UIGestureRecognizer) -> Void {
        //print("handlePostsTap")
    }

    func handleFollowersTap(gesture: UIGestureRecognizer) -> Void {
        //print("handleFollowersTap")
    }

    func handleFollowingTap(gesture: UIGestureRecognizer) -> Void {
        //print("handleFollowingTap")
    }

    func loadPostCount() -> Void {
        FbaseDataService.ds.getUserPostCount(self.user.uid, withCompletionBlock: {
            (count) in
            self.postsCountLabel.text = String(count)
        })
    }

    func loadLikeCount() -> Void {
        FbaseDataService.ds.getUserPosts(self.user.uid, withCompletionBlock: {
            (snapshot) in
            if snapshot.childrenCount > 0 {
                var starsCount = 0

                // Get star counts for posts and tally
                for (pid, _) in snapshot.value as! Dictionary<String, AnyObject> {
                    FbaseDataService.ds.getPostStarCount(pid, withCompletionBlock: {
                        (count) in
                        if count > 0 {
                            starsCount = starsCount + count
                            self.starsCountLabel.text = String(starsCount)
                        }
                    })
                }
            }
        })
    }

    func loadFollowerCount() -> Void {
        FbaseDataService.ds.getUserFollowers(self.user.uid, withCompletionBlock: {
            (followers) in
            self.followersCountLabel.text = String(followers.childrenCount)
        })
    }

    func loadFollowingCount() -> Void {
        FbaseDataService.ds.getUserFollowings(self.user.uid, withCompletionBlock: {
            (followings) in
            self.followingCountLabel.text = String(followings.childrenCount)
        })
    }

}
