import UIKit
import Haneke

class PersonCell: UICollectionViewCell {

    @IBOutlet weak var profileImage: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()

        self.profileImage.hnk_cancelSetImage()
        self.profileImage.image = nil
    }

    func setPersonData(person: User) -> Void {
        // Set format
        let format = Format<UIImage>(name: "thumbnail", diskCapacity: 10 * 1024 * 1024) { image in
            return image
        }

        // Set user profile image in background
        let profileImageURL = NSURL(string: person.profileImageURL)
        self.profileImage.hnk_setImageFromURL(profileImageURL!, format: format)
    }

}
