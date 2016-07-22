import UIKit

class SettingsItemCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        self.layer.borderColor = CustomColor.VERY_LIGHT_GRAY.CGColor
        self.layer.borderWidth = 0.5
    }

}
