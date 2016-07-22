import UIKit

class MainBarButtonItem: UIBarButtonItem {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let attrs = [
            NSForegroundColorAttributeName: CustomColor.DEFAULT_BLUE,
            NSFontAttributeName : UIFont(name: "Roboto-Regular", size: 18)!
        ]
        self.setTitleTextAttributes(attrs, forState: UIControlState.Normal)
    }

}
