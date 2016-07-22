import UIKit
import Haneke

class PostPhotoCell: UICollectionViewCell {

    @IBOutlet weak var postImage: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()

        self.postImage.hnk_cancelSetImage()
        self.postImage.image = nil
    }

    func setPostData(post: Post) -> Void {
        // Set format
        let iconFormat = Format<UIImage>(name: "thumbnail", diskCapacity: 10 * 1024 * 1024) { image in
            return image
        }

        // Set post image
        let postImageURL = NSURL(string: post.imageURL)
        self.postImage.hnk_setImageFromURL(postImageURL!, format: iconFormat)
    }

}
