import UIKit

class RankingViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: @IBOutlet

    @IBOutlet weak var rankingTableView: UITableView!

    // MARK: Local Variables

    var personView: PersonViewController!
    var ranking: [User]!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Load people in system
        self.ranking = [User]()
        self.loadRanking()

        self.rankingTableView.delegate = self
        self.rankingTableView.dataSource = self

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = CustomColor.DEFAULT_BLUE
        refreshControl.addTarget(self, action: #selector(RankingViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.rankingTableView.addSubview(refreshControl)
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

    // MARK: UITableViewDelegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.ranking.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.rankingTableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER_RANK, forIndexPath: indexPath) as! RankingCell

        // Set cell data and layout
        cell.setRankingData(self.ranking[indexPath.row])

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier(SEGUE_PERSON, sender: self.ranking[indexPath.row])
    }

    // MARK: Helpers

    func loadRanking() -> Void {
        FbaseDataService.ds.getUserStats {
            (stats) in
            for stat in stats.children {
                let childSnapshot = stats.childSnapshotForPath(stat.key)
                if childSnapshot.value != nil {
                    let statData = self.convertSnapshotToDictionary(childSnapshot)
                    let userID = stat.key!

                    FbaseDataService.ds.getUser(userID!, withCompletionBlock: {
                        (user) in
                        var personData = self.convertSnapshotToDictionary(user)
                        personData[FBASE_USER_STATS] = statData
                        let user = User(data: personData)

                        // Check privacy settings
                        FbaseDataService.ds.getSettings(user.uid, withCompletionBlock: {
                            (settings) in
                            if settings.childrenCount == 0 {
                                self.ranking.append(user)
                            } else {
                                // Settings exists check privacy
                                let settings_data: Dictionary<String, AnyObject> = self.convertSnapshotToDictionary(settings)
                                let hideFromPeopleList = settings_data[FBASE_USER_SETTING_PRIVACY_HIDE_FROM_PEOPLE_LIST] as! Bool
                                if !hideFromPeopleList {
                                    self.ranking.append(user)
                                }
                            }

                            // Resort descending
                            self.ranking.sortInPlace({ (first, second) -> Bool in
                                let firstCount = first.stats[FBASE_USER_STAT_POST_COUNT]! as Int
                                let secondCount = second.stats[FBASE_USER_STAT_POST_COUNT]! as Int
                                return firstCount > secondCount
                            })

                            // Refresh table
                            self.rankingTableView.reloadData()
                        })

                    })
                }
            }
        }
    }

    func reloadRanking() -> Void {
        self.ranking.removeAll()
        self.loadRanking()
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        // Reload data
        self.reloadRanking()

        // Delay and end spinner
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            refreshControl.endRefreshing()
        }
    }

}
