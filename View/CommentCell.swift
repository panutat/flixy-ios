import UIKit
import Haneke

class CommentCell: UITableViewCell {

    @IBOutlet weak var userProfileImage: ProfileImage!
    @IBOutlet weak var userDisplayName: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var timeAgo: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.userProfileImage.hnk_cancelSetImage()
        self.userProfileImage.image = nil
    }

    func setCommentData(comment: Comment) -> Void {
        // Set background color
        self.backgroundColor = CustomColor.VERY_LIGHT_GRAY

        // Set user display name
        self.userDisplayName.text = comment.userDisplayName

        // Set format
        let format = Format<UIImage>(name: "thumbnail", diskCapacity: 10 * 1024 * 1024) { image in
            return image
        }

        // Set user profile image in background
        self.userProfileImage.image = nil
        let userProfileImageURL = NSURL(string: comment.userProfileImageURL)
        self.userProfileImage.hnk_setImageFromURL(userProfileImageURL!, format: format)

        // Set message
        self.message.text = comment.message
        self.message.numberOfLines = 0
        self.message.lineBreakMode = .ByWordWrapping
        self.message.sizeToFit()

        // Set time ago
        let interval = NSTimeInterval.init(NSNumber(integer: Int(comment.timestamp)! / 1000))
        let date = NSDate(timeIntervalSince1970: interval)
        self.timeAgo.text = DateUtil.timeAgo(date)
    }
}
