import UIKit
import FBSDKShareKit
import MapKit
import AWSSNS

class PostDetailViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource, FBSDKSharingDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postImageHeightCon: NSLayoutConstraint!
    @IBOutlet weak var userProfileImage: ProfileImage!
    @IBOutlet weak var userDisplayName: UILabel!
    @IBOutlet weak var postTimestamp: UILabel!
    @IBOutlet weak var starCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var starButton: UIButton!

    @IBOutlet weak var commentTableView: UITableView!

    @IBOutlet weak var commentField: StandardTextField!

    // MARK: Local Variables

    var post: Post!
    var timelineParentView: TimelineViewController!
    var personParentView: PersonViewController!
    var homeParentView: HomeViewController!
    var comments: [Comment]!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Load posts in region
        self.comments = [Comment]()
        self.loadComments()

        self.commentTableView.delegate = self
        self.commentTableView.dataSource = self

        // Set table view layout
        self.commentTableView.backgroundColor = CustomColor.VERY_LIGHT_GRAY
        self.commentTableView.estimatedRowHeight = 60.0
        self.commentTableView.rowHeight = UITableViewAutomaticDimension

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CustomColor.DEFAULT_BLUE
        refreshControl.addTarget(self, action: #selector(PostDetailViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.commentTableView.addSubview(refreshControl)

        // Add tap handler to profile image
        let postImageTap = UITapGestureRecognizer(target: self, action: #selector(PostDetailViewController.postImageTapHandler(_:)))
        self.postImage.addGestureRecognizer(postImageTap)
        self.postImage.userInteractionEnabled = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Setup header
        self.setupHeader()
        self.view.backgroundColor = CustomColor.VERY_LIGHT_GRAY

        // Fetch counts if not loaded
        if !self.post.countsLoaded {
            self.loadCounts()
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PersonViewController where segue.identifier == SEGUE_PERSON {
            self.personParentView = vc
            vc.parentView = self
            vc.person = sender as! User
        } else if let vc = segue.destinationViewController as? PostDetailMapViewController where segue.identifier == SEGUE_POST_DETAIL_MAP {
            vc.post = self.post
            vc.location = sender as! CLLocation
        }
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        // Update parent post array with current post
        if timelineParentView != nil {
            self.timelineParentView.updatePost(self.post)
        }

        if personParentView != nil {
            self.personParentView.updatePost(self.post)
        }

        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func mapButtonPressed(sender: UIBarButtonItem) {
        GfireDataService.ds.getPostLocation(self.post.pid, withCompletionBlock: {
            (location, error) in
            if error == nil {
                self.performSegueWithIdentifier(SEGUE_POST_DETAIL_MAP, sender: location)
            } else {
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_POST_LOCATION_NOT_FOUND)
            }
        })
    }

    @IBAction func starButtonPressed(sender: UIButton) {
        if self.post.userStarred {
            // Remove user star
            FbaseDataService.ds.deletePostStar(self.post.pid, uid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                self.post.userStarred = false
                self.post.subtractStarCount(1)
                self.starCountLabel.text = String(self.post.starCount)
                sender.setBackgroundImage(UIImage(named: "Icon-Star"), forState: UIControlState.Normal)
            })
        } else {
            // Create user star
            FbaseDataService.ds.createPostStar(self.post.pid, uid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                self.post.userStarred = true
                self.post.addStarCount(1)
                self.starCountLabel.text = String(self.post.starCount)
                sender.setBackgroundImage(UIImage(named: "Icon-StarOn"), forState: UIControlState.Normal)

                // Send notification
                FbaseDataService.ds.getSettings(self.post.uid, withCompletionBlock: {
                    (settings) in
                    if settings.childrenCount > 0 {
                        // Check if allowed
                        let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                        if settings_data[FBASE_USER_SETTING_NOTIFICATION_POST_STAR] as! Bool {
                            // Don't send notification to yourself
                            if self.user.uid != self.post.uid {
                                FbaseDataService.ds.getUser(self.post.uid, withCompletionBlock: {
                                    (user) in
                                    if user.value != nil {
                                        let userData = user.value as! Dictionary<String, AnyObject>
                                        let person = User(data: userData)

                                        var displayName = "Someone"
                                        if self.user.displayName != "" {
                                            displayName = self.user.displayName
                                        }

                                        // Create payload
                                        let payload = [
                                            "type" : "postStar",
                                            "pid" : self.post.pid
                                        ]

                                        AWSSNSService.sendNotification(person, message: "\(displayName) starred your post!", payload: payload)
                                    }
                                })
                            }
                        }
                    }
                })
            })
        }
    }

    @IBAction func shareButtonPressed(sender: UIButton) {
        let photo = FBSDKSharePhoto()
        photo.image = self.postImage.image
        photo.userGenerated = true

        let content = FBSDKSharePhotoContent()
        content.photos = [photo]

        let dialog = FBSDKShareDialog()
        dialog.shareContent = content
        dialog.delegate = self
        dialog.fromViewController = self

        // Determine dialog mode
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "fbauth2://")!) {
            dialog.mode = FBSDKShareDialogMode.Native
        } else {
            dialog.mode = FBSDKShareDialogMode.Browser
        }

        dialog.show()
    }

    @IBAction func postButtonPressed(sender: UIButton) {
        // Check comment is valid
        if let message = self.commentField.text where !message.isEmpty {
            // Create comment in Firebase
            let trimmedMessage = message.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            FbaseDataService.ds.createPostComment(post.pid, uid: self.user.uid, message: trimmedMessage, withCompletionBlock: {
                (error, ref, cid) in
                if error == nil {
                    // Hide keyboard
                    self.commentField.resignFirstResponder()

                    // Clear field if success
                    self.commentField.text = ""

                    // Increment comment count
                    self.post.addCommentCount(1)

                    // Set comment count
                    self.commentCountLabel.text = String(self.post.commentCount)

                    // Reload comments
                    self.reloadComments()

                    // Send notification
                    FbaseDataService.ds.getSettings(self.post.uid, withCompletionBlock: {
                        (settings) in
                        if settings.childrenCount > 0 {
                            // Check if allowed
                            let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                            if settings_data[FBASE_USER_SETTING_NOTIFICATION_POST_COMMENT] as! Bool {
                                // Don't send notification to yourself
                                if self.user.uid != self.post.uid {
                                    FbaseDataService.ds.getUser(self.post.uid, withCompletionBlock: {
                                        (user) in
                                        if user.value != nil {
                                            let userData = user.value as! Dictionary<String, AnyObject>
                                            let person = User(data: userData)

                                            var displayName = "Someone"
                                            if self.user.displayName != "" {
                                                displayName = self.user.displayName
                                            }

                                            // Create payload
                                            let payload = [
                                                "type" : "postComment",
                                                "pid" : self.post.pid
                                            ]

                                            AWSSNSService.sendNotification(person, message: "\(displayName) commented on your post!", payload: payload)
                                        }
                                    })
                                }
                            }
                        }
                    })
                } else {
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_COMMENT_SEND_FAILED)
                }
            })
        } else {
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_INVALID_COMMENT)
        }
    }

    @IBAction func flagButtonPressed(sender: UIButton) {
        let confirmView = self.showConfirm(ALERT_MESSAGE_TITLE_CONFIRM, msg: ALERT_MESSAGE_CONFIRM_POST_FLAG)
        confirmView.setTextTheme(AlertViewController.TextColorTheme.Dark)
        confirmView.addAction({
            // Check if user has already flagged
            FbaseDataService.ds.checkPostUserFlag(self.post.pid, uid: self.user.uid, withCompletionBlock: {
                (exist) in
                if exist == false {
                    // Create Post Report
                    FbaseDataService.ds.createPostFlag(self.post.pid, uid: self.user.uid, withCompletionBlock: {
                        (error, ref) in

                    });
                }
            });
        })
    }

    // MARK: UITableViewDelegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // If no comments, let user know
        if self.comments.count == 0 {
            let noDataLabel = UILabel(frame: CGRectMake(0, 0, self.commentTableView.bounds.size.width, self.commentTableView.bounds.size.height))
            noDataLabel.text = "No comments"
            noDataLabel.textColor = UIColor.grayColor()
            noDataLabel.textAlignment = NSTextAlignment.Center
            self.commentTableView.backgroundView = noDataLabel
        } else {
            self.commentTableView.backgroundView = nil;
        }

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.commentTableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER_COMMENT, forIndexPath: indexPath) as! CommentCell

        // Set cell data and layout
        cell.setCommentData(self.comments[indexPath.row])

        // Add tap handler to profile image
        let profileImageTap = UITapGestureRecognizer(target: self, action: #selector(PostDetailViewController.commentProfileImageTapHandler(_:)))
        cell.userProfileImage.addGestureRecognizer(profileImageTap)

        return cell
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Only allow users to delete their own comments
        let comment = self.comments[indexPath.row]
        return comment.uid == self.user.uid
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let comment = self.comments[indexPath.row]

            let confirmView = self.showConfirm(ALERT_MESSAGE_TITLE_CONFIRM, msg: ALERT_MESSAGE_CONFIRM_DELETE_COMMENT)
            confirmView.setTextTheme(AlertViewController.TextColorTheme.Dark)
            confirmView.addCancelAction({
                self.commentTableView.setEditing(false, animated: true)
            })
            confirmView.addAction({
                // Delete from Firebase
                FbaseDataService.ds.deletePostComment(comment.pcid, withCompletionBlock: {
                    (error, ref) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // Increment comment count
                        self.post.subtractCommentCount(1)

                        // Set comment count
                        self.commentCountLabel.text = String(self.post.commentCount)

                        // Remove post from array
                        self.comments.removeAtIndex(indexPath.row)

                        // Refresh table
                        self.commentTableView.reloadData()
                    })
                })
            })
        }
    }

    // MARK: FBSDKSharingDelegate

    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_FACEBOOK_POST_SUCCESS)
    }

    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_FACEBOOK_POST_FAILED)
    }

    func sharerDidCancel(sharer: FBSDKSharing!) {
        //print("sharerDidCancel")
    }

    // MARK: Helpers

    func postImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        self.postImage.layoutIfNeeded()

        if self.postImage.frame.width != self.postImage.frame.height {
            // Unshrink
            let width = self.postImage.frame.width
            self.postImageHeightCon.constant = width

            let sublayer = self.postImage.layer.sublayers![0] as CALayer
            sublayer.frame = CGRectMake(0, self.postImage.frame.origin.y, width, width)

            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            // Reshrink
            self.postImageHeightCon.constant = 200.0

            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        // Reload data
        self.reloadComments()

        // Delay and end spinner
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            refreshControl.endRefreshing()
        }
    }

    func reloadComments() -> Void {
        self.comments.removeAll()
        self.loadComments()
    }

    func loadComments() -> Void {
        // Get comments for post
        FbaseDataService.ds.getPostComments(self.post.pid, withCompletionBlock: {
            (comments) in
            for comment in comments.children {
                let childSnapshot = comments.childSnapshotForPath(comment.key)
                if childSnapshot.value != nil {
                    let commentData = self.convertSnapshotToDictionary(childSnapshot)

                    // Create post object
                    let pcid = childSnapshot.key
                    let pid = commentData[FBASE_POST_COMMENT_PID] as! String
                    let uid = commentData[FBASE_POST_COMMENT_UID] as! String
                    let message = commentData[FBASE_POST_COMMENT_MESSAGE] as! String
                    let timestamp = commentData[FBASE_POST_COMMENT_TIMESTAMP]?.stringValue

                    // Get user data
                    FbaseDataService.ds.getUser(uid, withCompletionBlock: {
                        (user) in
                        if user.value != nil {
                            let userData = self.convertSnapshotToDictionary(user)
                            let userDisplayName = userData[FBASE_USER_DISPLAY_NAME] as! String
                            let userProfileImageURL = userData[FBASE_USER_PROFILE_IMAGE_URL] as! String

                            let comment = Comment(pcid: pcid, pid: pid, uid: uid, message: message, timestamp: timestamp!, userDisplayName: userDisplayName, userProfileImageURL: userProfileImageURL)

                            // Store comment
                            self.comments.append(comment)

                            // Sort comments from oldest first
                            self.comments.sortInPlace({$0.timestamp < $1.timestamp})

                            // Reload table data
                            self.commentTableView.reloadData()
                        }
                    })
                }
            }
        })
    }

    func loadCounts() -> Void {
        // Check if user starred post
        FbaseDataService.ds.checkPostUserStar(self.post.pid, uid: self.user.uid, withCompletionBlock: {
            (exist) in
            let userStarred = exist

            // Get star count
            FbaseDataService.ds.getPostStarCount(self.post.pid, withCompletionBlock: {
                (count) in
                let starCount = count

                // Get comment count
                FbaseDataService.ds.getPostCommentCount(self.post.pid, withCompletionBlock: {
                    (count) in
                    let commentCount = count

                    // Set counts loaded flag
                    self.post.countsLoaded = true

                    // Set star count
                    self.post.starCount = starCount

                    // Set comment count
                    self.post.commentCount = commentCount

                    // Set user starred
                    self.post.userStarred = userStarred

                    // Set comment count label
                    self.commentCountLabel.text = String(self.post.commentCount)

                    // Set star count label
                    self.starCountLabel.text = String(self.post.starCount)

                    // Set if user starred
                    if self.post.userStarred {
                        self.starButton.setBackgroundImage(UIImage(named: "Icon-StarOn"), forState: UIControlState.Normal)
                    } else {
                        self.starButton.setBackgroundImage(UIImage(named: "Icon-Star"), forState: UIControlState.Normal)
                    }
                })
            })
        })
    }

    func setupHeader() -> Void {
        // Add dark gradient overlay
        let gradient = CAGradientLayer()
        gradient.frame = self.postImage.frame
        gradient.colors = [
            UIColor(white: 0.0, alpha: 0.0).CGColor,
            UIColor(white: 0.0, alpha: 0.4).CGColor
        ]
        self.postImage.layer.sublayers?.removeAll()
        self.postImage.layer.insertSublayer(gradient, atIndex: 0)

        // Get image from URL and set image in background
        self.postImage.image = nil
        self.postImage.clipsToBounds = true
        let imageURL = NSURL(string: post.imageURL)
        self.postImage.hnk_setImageFromURL(imageURL!)

        // Set user display name
        self.userDisplayName.text = post.userDisplayName

        // Set user profile image in background
        self.userProfileImage.image = nil
        let userProfileImageURL = NSURL(string: post.userProfileImageURL)
        self.userProfileImage.hnk_setImageFromURL(userProfileImageURL!)

        // Set post timestamp
        let interval = NSTimeInterval.init(NSNumber(integer: Int(post.timestamp)! / 1000))
        let date = NSDate(timeIntervalSince1970: interval)
        self.postTimestamp.text = DateUtil.timeAgo(date)

        // Set comment count
        self.commentCountLabel.text = String(self.post.commentCount)

        // Set star count
        self.starCountLabel.text = String(self.post.starCount)

        // Set if user starred
        if self.post.userStarred {
            self.starButton.setBackgroundImage(UIImage(named: "Icon-StarOn"), forState: UIControlState.Normal)
        } else {
            self.starButton.setBackgroundImage(UIImage(named: "Icon-Star"), forState: UIControlState.Normal)
        }

        // Add tap handler to profile image
        let profileImageTap = UITapGestureRecognizer(target: self, action: #selector(PostDetailViewController.profileImageTapHandler(_:)))
        self.userProfileImage.addGestureRecognizer(profileImageTap)
    }

    func profileImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        // Get user from Firebase
        FbaseDataService.ds.getUser(self.post.uid, withCompletionBlock: {
            (user) in
            if user.value != nil {
                let userData = self.convertSnapshotToDictionary(user)
                let person = User(data: userData)

                // Segue to person view
                self.performSegueWithIdentifier(SEGUE_PERSON, sender: person)
            }
        })
    }

    func commentProfileImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        let row = self.getRowIndexFromSender(gesture, tableView: self.commentTableView)
        let comment = self.comments[row]

        // Get user from Firebase
        FbaseDataService.ds.getUser(comment.uid, withCompletionBlock: {
            (user) in
            if user.value != nil {
                let userData = user.value as! Dictionary<String, AnyObject>
                let person = User(data: userData)

                // Segue to person view
                self.performSegueWithIdentifier(SEGUE_PERSON, sender: person)
            }
        })
    }

}
