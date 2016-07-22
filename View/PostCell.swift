import UIKit
import Haneke

class PostCell: UITableViewCell {

    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var userDisplayName: UILabel!
    @IBOutlet weak var userProfileImage: ProfileImage!
    @IBOutlet weak var postTimestamp: UILabel!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var starCountLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.postImage.hnk_cancelSetImage()
        self.postImage.image = nil

        self.userProfileImage.hnk_cancelSetImage()
        self.userProfileImage.image = nil
    }

    func setPostData(post: Post) -> Void {
        // Add dark gradient overlay
        let gradient = CAGradientLayer()
        gradient.frame = self.postImage.frame
        gradient.colors = [
            UIColor(white: 0.0, alpha: 0.0).CGColor,
            UIColor(white: 0.0, alpha: 0.4).CGColor
        ]
        self.postImage.layer.sublayers?.removeAll()
        self.postImage.layer.insertSublayer(gradient, atIndex: 0)

        // Set format
        let format = Format<UIImage>(name: "thumbnail", diskCapacity: 10 * 1024 * 1024) { image in
            return image
        }

        // Get image from URL and set image in background
        let imageURL = NSURL(string: post.imageURL)
        self.postImage.hnk_setImageFromURL(imageURL!, format: format)

        // Set user display name
        self.userDisplayName.text = post.userDisplayName

        // Set user profile image in background
        let userProfileImageURL = NSURL(string: post.userProfileImageURL)
        self.userProfileImage.hnk_setImageFromURL(userProfileImageURL!, format: format)

        // Set post timestamp
        let interval = NSTimeInterval.init(NSNumber(integer: Int(post.timestamp)! / 1000))
        let date = NSDate(timeIntervalSince1970: interval)
        self.postTimestamp.text = DateUtil.timeAgo(date)

        // Set comment count
        self.commentCountLabel.text = String(post.commentCount)

        // Set star count
        self.starCountLabel.text = String(post.starCount)

        // Set if user starred
        if post.userStarred {
            self.starButton.setBackgroundImage(UIImage(named: "Icon-StarOn"), forState: UIControlState.Normal)
        } else {
            self.starButton.setBackgroundImage(UIImage(named: "Icon-Star"), forState: UIControlState.Normal)
        }
    }

}
