import UIKit

class SearchTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.borderStyle = UITextBorderStyle.Line
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 0.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = CustomColor.TEXT_FIELD_BORDER_DARK.CGColor
        self.font = UIFont.systemFontOfSize(14)
        self.textColor = CustomColor.TEXT_FIELD_TEXT
        self.backgroundColor = CustomColor.TEXT_FIELD_BACKGROUND
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectMake(bounds.origin.x + 12, bounds.origin.y + 8, bounds.size.width - 24, bounds.size.height - 16);
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return self.textRectForBounds(bounds);
    }

}
