import UIKit

class MenuIconView: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.cornerRadius = self.layer.frame.width / 2
        self.layer.borderWidth = 2
        self.layer.borderColor = CustomColor.ICON_BUTTON_BORDER.CGColor
    }

}
