import UIKit

class StandardTextLabel: UILabel {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.font = UIFont.systemFontOfSize(14)
        self.textColor = CustomColor.TEXT_FIELD_LABEL
    }

}
