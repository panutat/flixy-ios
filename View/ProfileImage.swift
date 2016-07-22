import UIKit

class ProfileImage: UIImageView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.cornerRadius = self.bounds.size.width / 2
        self.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.bounds.size.width / 2
    }

}
