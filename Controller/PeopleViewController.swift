import UIKit

class PeopleViewController: CommonViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: @IBOutlet

    @IBOutlet weak var personCollectionView: UICollectionView!
    @IBOutlet weak var everyoneButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!

    // MARK: Local Variables

    var personCellLayout: PersonCellLayout!
    var personView: PersonViewController!
    var persons: [User]!
    var filter: PeopleFilterType!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Set default filter
        self.setDefaultFilter()
        self.setFilterDisplay()

        // Load people in system
        self.persons = [User]()
        self.loadPersons()

        self.view.backgroundColor = CustomColor.VERY_LIGHT_GRAY

        self.personCollectionView.delegate = self
        self.personCollectionView.dataSource = self

        self.personCellLayout = PersonCellLayout()
        self.personCollectionView.collectionViewLayout = personCellLayout
        self.personCollectionView.backgroundColor = CustomColor.VERY_LIGHT_GRAY
        self.personCollectionView.alwaysBounceVertical = true

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CustomColor.DEFAULT_BLUE
        refreshControl.addTarget(self, action: #selector(PeopleViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.personCollectionView.addSubview(refreshControl)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PersonViewController where segue.identifier == SEGUE_PERSON {
            self.personView = vc
            vc.parentView = self
            vc.person = sender as! User
        }
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func everyoneButtonPressed(sender: UIButton) {
        self.filter = PeopleFilterType.Everyone
        self.setFilterDisplay()
        self.reloadPersons()
    }

    @IBAction func followersButtonPressed(sender: UIButton) {
        self.filter = PeopleFilterType.Followers
        self.setFilterDisplay()
        self.reloadPersons()
    }

    @IBAction func followingButtonPressed(sender: UIButton) {
        self.filter = PeopleFilterType.Following
        self.setFilterDisplay()
        self.reloadPersons()
    }

    // MARK: UICollectionViewDelegate

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.persons.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.personCollectionView.dequeueReusableCellWithReuseIdentifier(CELL_IDENTIFIER_PERSON, forIndexPath: indexPath) as! PersonCell

        // Set cell data and layout
        cell.setPersonData(self.persons[indexPath.row])

        // Add tap handler to profile image
        let profileImageTap = UITapGestureRecognizer(target: self, action: #selector(PeopleViewController.profileImageTapHandler(_:)))
        cell.profileImage.addGestureRecognizer(profileImageTap)
        cell.profileImage.userInteractionEnabled = true

        return cell
    }

    // MARK: Helpers

    func setFilterDisplay() -> Void {
        if self.filter == PeopleFilterType.Everyone {
            self.everyoneButton.setTitleColor(CustomColor.DEFAULT_BLUE, forState: UIControlState.Normal)
            self.followersButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.followingButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        } else if self.filter == PeopleFilterType.Followers {
            self.everyoneButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.followersButton.setTitleColor(CustomColor.DEFAULT_BLUE, forState: UIControlState.Normal)
            self.followingButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        } else if self.filter == PeopleFilterType.Following {
            self.everyoneButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.followersButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.followingButton.setTitleColor(CustomColor.DEFAULT_BLUE, forState: UIControlState.Normal)
        }
    }

    func setDefaultFilter() -> Void {
        if self.filter == nil {
            self.filter = PeopleFilterType.Everyone
        }
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        // Reload data
        self.reloadPersons()

        // Delay and end spinner
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            refreshControl.endRefreshing()
        }
    }

    func reloadPersons() -> Void {
        // Clear stored persons
        self.persons.removeAll()

        // Clear collection view
        self.personCollectionView.reloadData()

        // Fetch and load
        self.loadPersons()
    }

    func profileImageTapHandler(gesture: UITapGestureRecognizer) -> Void {
        let row = self.getCellIndexFromSender(gesture, collectionView: self.personCollectionView)
        let person = self.persons[row]

        // Get user from Firebase
        FbaseDataService.ds.getUser(person.uid, withCompletionBlock: {
            (user) in
            if user.value != nil {
                let userData = user.value as! Dictionary<String, AnyObject>
                let person = User(data: userData)

                // Segue to person view
                self.performSegueWithIdentifier(SEGUE_PERSON, sender: person)
            }
        })
    }

    func loadPersons() -> Void {
        if self.filter == PeopleFilterType.Everyone {
            FbaseDataService.ds.getUsers {
                (users) in
                for user in users.children {
                    let childSnapshot = users.childSnapshotForPath(user.key)
                    if childSnapshot.value != nil {
                        let personData = self.convertSnapshotToDictionary(childSnapshot)
                        let user = User(data: personData)

                        // Check privacy settings
                        FbaseDataService.ds.getSettings(user.uid, withCompletionBlock: {
                            (settings) in
                            if settings.childrenCount == 0 {
                                self.persons.append(user)
                            } else {
                                // Settings exists check privacy
                                let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                                let hideFromPeopleList = settings_data[FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST] as! Bool
                                if !hideFromPeopleList {
                                    self.persons.append(user)
                                }
                            }

                            // Reload table data
                            self.personCollectionView.reloadData()
                        })
                    }
                }
            }
        } else if self.filter == PeopleFilterType.Followers {
            FbaseDataService.ds.getUserFollowers(self.user.uid, withCompletionBlock: {
                (followers) in
                for follower in followers.children {
                    let followerSnapshot = followers.childSnapshotForPath(follower.key)
                    FbaseDataService.ds.getUser(followerSnapshot.key, withCompletionBlock: {
                        (user) in
                        let personData = self.convertSnapshotToDictionary(user)
                        let user = User(data: personData)
                        self.persons.append(user)

                        // Reload table data
                        self.personCollectionView.reloadData()
                    })
                }
            })
        } else if self.filter == PeopleFilterType.Following {
            FbaseDataService.ds.getUserFollowings(self.user.uid, withCompletionBlock: {
                (followings) in
                for following in followings.children {
                    let followingSnapshot = followings.childSnapshotForPath(following.key)
                    FbaseDataService.ds.getUser(followingSnapshot.key, withCompletionBlock: {
                        (user) in
                        let personData = self.convertSnapshotToDictionary(user)
                        let user = User(data: personData)
                        self.persons.append(user)

                        // Reload table data
                        self.personCollectionView.reloadData()
                    })
                }
            })
        }
    }
}
