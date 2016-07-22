import UIKit

class LoginTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.borderStyle = UITextBorderStyle.None
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 0.0
        self.font = UIFont.systemFontOfSize(18)
        self.textColor = CustomColor.TEXT_FIELD_TEXT
        self.backgroundColor = CustomColor.TEXT_FIELD_BACKGROUND
        self.alpha = 1.0
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectMake(bounds.origin.x + 15, bounds.origin.y + 8, bounds.size.width - 30, bounds.size.height - 16);
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return self.textRectForBounds(bounds);
    }

}
