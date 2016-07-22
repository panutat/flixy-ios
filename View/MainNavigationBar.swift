import UIKit

class MainNavigationBar: UINavigationBar {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let attrs = [
            NSForegroundColorAttributeName: CustomColor.DEFAULT_BLUE,
            NSFontAttributeName : UIFont(name: "Roboto-Medium", size: 22)!
        ]
        self.titleTextAttributes = attrs

        self.barTintColor = CustomColor.VERY_LIGHT_GRAY
        self.translucent = false
    }

}
