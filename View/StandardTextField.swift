import UIKit

class StandardTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.borderStyle = UITextBorderStyle.None
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 0.0
        self.font = UIFont.systemFontOfSize(16)
        self.textColor = CustomColor.TEXT_FIELD_TEXT
        self.backgroundColor = CustomColor.TEXT_FIELD_BACKGROUND

        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = CustomColor.TEXT_FIELD_BORDER.CGColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = width
        self.layer.addSublayer(border)
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectMake(bounds.origin.x + 12, bounds.origin.y + 8, bounds.size.width - 24, bounds.size.height - 16);
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return self.textRectForBounds(bounds);
    }

}
