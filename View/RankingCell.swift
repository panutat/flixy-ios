import UIKit
import Haneke

class RankingCell: UITableViewCell {

    @IBOutlet weak var userProfileImage: ProfileImage!
    @IBOutlet weak var userDisplayName: UILabel!
    @IBOutlet weak var userPoints: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.userProfileImage.hnk_cancelSetImage()
        self.userProfileImage.image = nil

        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    func setRankingData(user: User) -> Void {
        // Set user display name
        self.userDisplayName.text = user.displayName

        // Set user points
        self.userPoints.text = String(user.stats[FBASE_USER_STAT_POST_COUNT]!) + " pts"

        // Set format
        let format = Format<UIImage>(name: "thumbnail", diskCapacity: 10 * 1024 * 1024) { image in
            return image
        }

        // Set user profile image in background
        let userProfileImageURL = NSURL(string: user.profileImageURL)
        self.userProfileImage.hnk_setImageFromURL(userProfileImageURL!, format: format)
    }
}
