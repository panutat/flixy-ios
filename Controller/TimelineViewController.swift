import UIKit
import MapKit
import FBSDKShareKit
import Haneke

class TimelineViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource, FBSDKSharingDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var postTableView: UITableView!

    // MARK: Local Variables

    var parentView: HomeViewController!
    var postDetailView: PostDetailViewController!
    var personView: PersonViewController!
    var region: MKCoordinateRegion!
    var posts: [Post]!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Load posts in region
        self.posts = [Post]()
        self.loadPosts()

        self.postTableView.delegate = self
        self.postTableView.dataSource = self

        self.postTableView.backgroundColor = CustomColor.VERY_LIGHT_GRAY

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CustomColor.DEFAULT_BLUE
        refreshControl.addTarget(self, action: #selector(TimelineViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.postTableView.addSubview(refreshControl)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PostDetailViewController where segue.identifier == SEGUE_POST_DETAIL {
            self.postDetailView = vc
            vc.timelineParentView = self
            vc.post = sender as! Post
        } else if let vc = segue.destinationViewController as? PersonViewController where segue.identifier == SEGUE_PERSON {
            self.personView = vc
            vc.parentView = self
            vc.person = sender as! User
        }
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func starButtonPressed(sender: UIButton) {
        let row = self.getRowIndexFromSender(sender, tableView: self.postTableView)
        let position = sender.convertPoint(CGPointZero, toView: self.postTableView)
        let indexPath = self.postTableView.indexPathForRowAtPoint(position)
        let cell = postTableView.cellForRowAtIndexPath(indexPath!) as! PostCell
        if self.posts[row].userStarred {
            // Remove user star
            FbaseDataService.ds.deletePostStar(self.posts[row].pid, uid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                self.posts[row].userStarred = false
                self.posts[row].subtractStarCount(1)
                cell.starCountLabel.text = String(self.posts[row].starCount)
                sender.setBackgroundImage(UIImage(named: "Icon-Star"), forState: UIControlState.Normal)

                // Update star count

            })
        } else {
            // Create user star
            FbaseDataService.ds.createPostStar(self.posts[row].pid, uid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                self.posts[row].userStarred = true
                self.posts[row].addStarCount(1)
                cell.starCountLabel.text = String(self.posts[row].starCount)
                sender.setBackgroundImage(UIImage(named: "Icon-StarOn"), forState: UIControlState.Normal)

                // Send notification
                FbaseDataService.ds.getSettings(self.posts[row].uid, withCompletionBlock: {
                    (settings) in
                    if settings.childrenCount > 0 {
                        // Check if allowed
                        let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                        if settings_data[FBASE_USER_SETTING_NOTIFICATION_POST_STAR] as! Bool {
                            // Don't send notification to yourself
                            if self.user.uid != self.posts[row].uid {
                                FbaseDataService.ds.getUser(self.posts[row].uid, withCompletionBlock: {
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
                                            "pid" : self.posts[row].pid
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

    @IBAction func commentButtonPressed(sender: UIButton) {
        let row = self.getRowIndexFromSender(sender, tableView: self.postTableView)
        self.performSegueWithIdentifier(SEGUE_POST_DETAIL, sender: self.posts[row])
    }

    @IBAction func shareButtonPressed(sender: UIButton) {
        // Get corresponding cell
        let position = sender.convertPoint(CGPointZero, toView: self.postTableView)
        let indexPath = self.postTableView.indexPathForRowAtPoint(position)
        let cell = self.postTableView.cellForRowAtIndexPath(indexPath!) as! PostCell

        let photo = FBSDKSharePhoto()
        photo.image = cell.postImage.image
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

    // MARK: UITableViewDelegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.posts.count == 0 {
            let noDataLabel = UILabel(frame: CGRectMake(0, 0, self.postTableView.bounds.size.width, self.postTableView.bounds.size.height))
            noDataLabel.text = "No posts"
            noDataLabel.textColor = UIColor.grayColor()
            noDataLabel.textAlignment = NSTextAlignment.Center
            self.postTableView.backgroundView = noDataLabel
        } else {
            self.postTableView.backgroundView = nil;
        }

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.postTableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER_POST, forIndexPath: indexPath) as! PostCell

        // Set cell data and layout
        cell.setPostData(self.posts[indexPath.row])

        // Add tap handler to profile image
        let profileImageTap = UITapGestureRecognizer(target: self, action: #selector(TimelineViewController.profileImageTapHandler(_:)))
        cell.userProfileImage.addGestureRecognizer(profileImageTap)
        cell.userProfileImage.userInteractionEnabled = true

        // Add tap handler to post image
        let postImageTap = UITapGestureRecognizer(target: self, action: #selector(TimelineViewController.postImageTapHandler(_:)))
        cell.postImage.addGestureRecognizer(postImageTap)
        cell.postImage.userInteractionEnabled = true

        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.postTableView.bounds.width
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Only allow users to delete their own posts
        let post = self.posts[indexPath.row]
        return post.uid == self.user.uid
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let post = self.posts[indexPath.row]

            let confirmView = self.showConfirm(ALERT_MESSAGE_TITLE_CONFIRM, msg: ALERT_MESSAGE_CONFIRM_DELETE_POST)
            confirmView.setTextTheme(AlertViewController.TextColorTheme.Dark)
            confirmView.addCancelAction({
                self.postTableView.setEditing(false, animated: true)
            })
            confirmView.addAction({
                // Delete post location from Firebase
                GfireDataService.ds.deletePostLocation(post.pid, withCompletionBlock: {
                    (error) in
                    if error == nil {
                        // Delete post, post comments and stars from Firebase
                        FbaseDataService.ds.deletePostCascade(post.pid, withCompletionBlock: {
                            (error, ref) in
                            if error == nil {
                                // Delete post image from AWS S3
                                AWSS3Service.deletePostImage(post.imageURL, withCompletionBlock: {
                                    (success) in

                                    dispatch_async(dispatch_get_main_queue(), {
                                        // Remove post from array
                                        self.posts.removeAtIndex(indexPath.row)

                                        // Refresh table
                                        self.postTableView.reloadData()
                                    })
                                })
                            }
                        })
                    }
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

    func profileImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        let row = self.getRowIndexFromSender(gesture, tableView: self.postTableView)
        let post = self.posts[row]

        // Get user from Firebase
        FbaseDataService.ds.getUser(post.uid, withCompletionBlock: {
            (user) in
            if user.value != nil {
                let userData = user.value as! Dictionary<String, AnyObject>
                let person = User(data: userData)

                // Segue to person view
                self.performSegueWithIdentifier(SEGUE_PERSON, sender: person)
            }
        })
    }

    func postImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        let row = self.getRowIndexFromSender(gesture, tableView: self.postTableView)
        self.performSegueWithIdentifier(SEGUE_POST_DETAIL, sender: self.posts[row])
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        // Reload data
        self.reloadPosts()

        // Delay and end spinner
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            refreshControl.endRefreshing()
        }
    }

    func updatePost(updatePost: Post) -> Void {
        for (index, post) in self.posts.enumerate() {
            if post.pid == updatePost.pid {
                // Match found, swap in array
                self.posts.removeAtIndex(index)
                self.posts.insert(updatePost, atIndex: index)

                // Update cell
                self.postTableView.beginUpdates()
                self.postTableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                self.postTableView.endUpdates()

                break
            }
        }
    }

    func reloadPosts() -> Void {
        self.posts.removeAll()
        self.loadPosts()
    }

    func loadPosts() -> Void {
        // Get posts in region
        GfireDataService.ds.queryPostsWithRegionOnce(self.region, withCompletionBlock: {
            (pid, location) in
            // Get post info
            FbaseDataService.ds.getPost(pid, withCompletionBlock: {
                (post) in
                if post.value != nil {
                    let postData = self.convertSnapshotToDictionary(post)

                    // Create post object
                    let uid = postData[FBASE_POST_UID] as! String
                    let imageURL = postData[FBASE_POST_IMAGE_URL] as! String
                    let timestamp = postData[FBASE_POST_TIMESTAMP]?.stringValue
                    let lat = location.coordinate.latitude
                    let lon = location.coordinate.longitude

                    // Get user data
                    FbaseDataService.ds.getUser(uid, withCompletionBlock: {
                        (user) in
                        if user.value != nil {
                            let userData = self.convertSnapshotToDictionary(user)
                            let userDisplayName = userData[FBASE_USER_DISPLAY_NAME] as! String
                            let userProfileImageURL = userData[FBASE_USER_PROFILE_IMAGE_URL] as! String

                            // Check if user starred post
                            FbaseDataService.ds.checkPostUserStar(post.key, uid: self.user.uid, withCompletionBlock: {
                                (exist) in
                                let userStarred = exist

                                // Get star count
                                FbaseDataService.ds.getPostStarCount(post.key, withCompletionBlock: {
                                    (count) in
                                    let starCount = count

                                    // Get comment count
                                    FbaseDataService.ds.getPostCommentCount(post.key, withCompletionBlock: {
                                        (count) in
                                        let commentCount = count

                                        let post = Post(pid: pid, uid: uid, imageURL: imageURL, timestamp: timestamp!, userDisplayName: userDisplayName, userProfileImageURL: userProfileImageURL, lat: lat, lon: lon, commentCount: commentCount, starCount: starCount, userStarred: userStarred)

                                        // Set counts loaded flag
                                        post.countsLoaded = true

                                        // Store post
                                        self.posts.append(post)

                                        // Sort posts most recent first
                                        self.posts.sortInPlace({$0.timestamp > $1.timestamp})

                                        // Reload table data
                                        self.postTableView.reloadData()
                                    })
                                })
                            })
                        }
                    })
                }
            })
        })
    }

}
