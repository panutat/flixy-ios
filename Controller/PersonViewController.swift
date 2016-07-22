import UIKit
import Firebase

class PersonViewController: CommonViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: @IBOutlet

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var personDisplayNameLabel: UINavigationItem!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var starsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var postPhotoCollectionView: UICollectionView!

    // MARK: Local Variables

    var person: User!
    var parentView: UIViewController!
    var postDetailView: PostDetailViewController!
    var postPhotoCellLayout: PostPhotoCellLayout!
    var posts: [Post]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Setup person info
        if !self.person.displayName.isEmpty {
            self.personDisplayNameLabel.title = self.person.displayName
        } else {
            self.personDisplayNameLabel.title = self.person.firstName
        }

        // Load people in system
        self.posts = [Post]()
        self.loadPosts()

        self.postPhotoCollectionView.delegate = self
        self.postPhotoCollectionView.dataSource = self

        self.postPhotoCellLayout = PostPhotoCellLayout()
        self.postPhotoCollectionView.collectionViewLayout = self.postPhotoCellLayout
        self.postPhotoCollectionView.backgroundColor = CustomColor.VERY_LIGHT_GRAY
        self.postPhotoCollectionView.alwaysBounceVertical = true

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CustomColor.DEFAULT_BLUE
        refreshControl.addTarget(self, action: #selector(PersonViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.postPhotoCollectionView.addSubview(refreshControl)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Set user follow status
        self.setFollowStatus()

        // Load user data in form
        if let profileImageURL = NSURL(string: self.person.profileImageURL) {
            self.profileImage.hnk_setImageFromURL(profileImageURL)
        }

        // Check privacy settings
        FbaseDataService.ds.getSettings(self.person.uid, withCompletionBlock: {
            (settings) in
            if settings.childrenCount == 0 {
                // Load counts
                self.loadCounts()
            } else {
                // Settings exists check privacy
                let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                let hideFromPeopleList = settings_data[FBASE_USER_SETTING_PRIVACY_HIDE_STAT_COUNTS] as! Bool
                if !hideFromPeopleList {
                    // Load counts
                    self.loadCounts()
                } else {
                    // Hide counts
                    self.hideCounts()
                }
            }
        })

        // Animated profile image
        let circleWidth = self.profileImage.bounds.width
        let circleHeight = circleWidth
        let animatedCircleView = AnimatedCircleView(frame: CGRectMake(0, 0, circleWidth, circleHeight))
        self.profileImage.addSubview(animatedCircleView)
        animatedCircleView.animateCircle(1.0)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PostDetailViewController where segue.identifier == SEGUE_POST_DETAIL {
            self.postDetailView = vc
            vc.personParentView = self
            vc.post = sender as! Post
        }
    }

    // MARK: IBActions

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UICollectionViewDelegate

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.postPhotoCollectionView.dequeueReusableCellWithReuseIdentifier(CELL_IDENTIFIER_POST_PHOTO, forIndexPath: indexPath) as! PostPhotoCell

        // Set cell data and layout
        cell.setPostData(self.posts[indexPath.row])

        // Add tap handler to profile image
        let postImageTap = UITapGestureRecognizer(target: self, action: #selector(PersonViewController.postImageTapHandler(_:)))
        cell.postImage.addGestureRecognizer(postImageTap)
        cell.postImage.userInteractionEnabled = true

        return cell
    }

    // MARK: Helpers

    func setFollowStatus() -> Void {
        // User cannot follow themselves
        if self.person.uid != self.user.uid {
            FbaseDataService.ds.getUserFollowing(self.user.uid, fid: self.person.uid, withCompletionBlock: {
                (follow) in
                if follow.childrenCount > 0 {
                    // Is following
                    let unfollowButton = UIBarButtonItem(title: BAR_BUTTON_UNFOLLOW, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PersonViewController.followButtonPressed(_:)))

                    // Style
                    let attrs = [
                        NSForegroundColorAttributeName: CustomColor.DEFAULT_BLUE,
                        NSFontAttributeName : UIFont(name: "Roboto-Regular", size: 18)!
                    ]
                    unfollowButton.setTitleTextAttributes(attrs, forState: UIControlState.Normal)

                    self.navigationBar.items?.first?.rightBarButtonItem = unfollowButton
                } else {
                    // It not following
                    let followButton = UIBarButtonItem(title: BAR_BUTTON_FOLLOW, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PersonViewController.followButtonPressed(_:)))

                    // Style
                    let attrs = [
                        NSForegroundColorAttributeName: CustomColor.DEFAULT_BLUE,
                        NSFontAttributeName : UIFont(name: "Roboto-Regular", size: 18)!
                    ]
                    followButton.setTitleTextAttributes(attrs, forState: UIControlState.Normal)

                    self.navigationBar.items?.first?.rightBarButtonItem = followButton
                }
            })
        }
    }

    func followButtonPressed(sender: UIBarButtonItem) {
        if let action = sender.title where action == BAR_BUTTON_FOLLOW {
            FbaseDataService.ds.createFollow(self.person.uid, fid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                if error != nil {
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_FOLLOW_FAILED)
                } else {
                    self.setFollowStatus()
                    self.loadFollowerCount()

                    // Send notification
                    FbaseDataService.ds.getSettings(self.person.uid, withCompletionBlock: {
                        (settings) in
                        if settings.childrenCount > 0 {
                            // Check if allowed
                            let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                            if settings_data[FBASE_USER_SETTING_NOTIFICATION_POST_STAR] as! Bool {
                                var displayName = "Someone"
                                if self.user.displayName != "" {
                                    displayName = self.user.displayName
                                }

                                // Create payload
                                let payload = [
                                    "type" : "newFollower",
                                    "uid" : self.user.uid!
                                ]

                                AWSSNSService.sendNotification(self.person, message: "\(displayName) started following you!", payload: payload)
                            }
                        }
                    })
                }
            })
        } else if let action = sender.title where action == BAR_BUTTON_UNFOLLOW {
            FbaseDataService.ds.deleteFollow(self.person.uid, fid: self.user.uid, withCompletionBlock: {
                (error, ref) in
                if error != nil {
                    self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_UNFOLLOW_FAILED)
                } else {
                    self.setFollowStatus()
                    self.loadFollowerCount()
                }
            })
        }
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        self.reloadPosts()
        refreshControl.endRefreshing()
    }

    func reloadPosts() -> Void {
        self.posts.removeAll()
        self.loadPosts()
    }

    func postImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        let row = self.getCellIndexFromSender(gesture, collectionView: self.postPhotoCollectionView)
        let post = self.posts[row]

        // Segue to post detail view
        self.performSegueWithIdentifier(SEGUE_POST_DETAIL, sender: post)
    }

    func loadPosts() -> Void {
        FbaseDataService.ds.getUserPosts(self.person.uid, withCompletionBlock: {
            (posts) in
            for post in posts.children {
                let childSnapshot = posts.childSnapshotForPath(post.key)
                if childSnapshot.value != nil {
                    let postData = self.convertSnapshotToDictionary(childSnapshot)

                    // Create post object
                    let pid = childSnapshot.key
                    let uid = postData[FBASE_POST_UID] as! String
                    let imageURL = postData[FBASE_POST_IMAGE_URL] as! String
                    let timestamp = postData[FBASE_POST_TIMESTAMP]?.stringValue

                    let post = Post(pid: pid, uid: uid, imageURL: imageURL, timestamp: timestamp!, userDisplayName: self.person.displayName, userProfileImageURL: self.person.profileImageURL, lat: 0.0, lon: 0.0, commentCount: 0, starCount: 0, userStarred: false)

                    // Store post
                    self.posts.append(post)

                    // Sort posts most recent first
                    self.posts.sortInPlace({$0.timestamp > $1.timestamp})

                    // Reload table data
                    self.postPhotoCollectionView.reloadData()
                }
            }
        })
    }

    func updatePost(updatePost: Post) -> Void {
        for (index, post) in self.posts.enumerate() {
            if post.pid == updatePost.pid {
                // Match found, swap in array
                self.posts.removeAtIndex(index)
                self.posts.insert(updatePost, atIndex: index)

                // Update cell
                self.postPhotoCollectionView.reloadItemsAtIndexPaths([NSIndexPath.init(forRow: index, inSection: 0)])

                break
            }
        }
    }

    func loadCounts() -> Void {
        // Load posts count
        self.loadPostCount()

        // Load likes count
        self.loadLikeCount()

        // Load follower count
        self.loadFollowerCount()

        // Load following count
        self.loadFollowingCount()
    }

    func hideCounts() -> Void {
        self.postsCountLabel.text = "-"
        self.starsCountLabel.text = "-"
        self.followersCountLabel.text = "-"
        self.followingCountLabel.text = "-"
    }

    func loadPostCount() -> Void {
        FbaseDataService.ds.getUserPostCount(self.person.uid, withCompletionBlock: {
            (count) in
            self.postsCountLabel.text = String(count)
        })
    }

    func loadLikeCount() -> Void {
        FbaseDataService.ds.getUserPosts(self.person.uid, withCompletionBlock: {
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
        FbaseDataService.ds.getUserFollowers(self.person.uid, withCompletionBlock: {
            (followers) in
            self.followersCountLabel.text = String(followers.childrenCount)
        })
    }

    func loadFollowingCount() -> Void {
        FbaseDataService.ds.getUserFollowings(self.person.uid, withCompletionBlock: {
            (followings) in
            self.followingCountLabel.text = String(followings.childrenCount)
        })
    }

}
