import UIKit

class PostPhotoCellLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    override var itemSize: CGSize {
        set {

        }
        get {
            let numberOfColumns: CGFloat = 3
            let itemWidth = (CGRectGetWidth(self.collectionView!.frame) - (numberOfColumns - 1)) / numberOfColumns
            return CGSizeMake(itemWidth, itemWidth)
        }
    }

    func setupLayout() {
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.scrollDirection = .Vertical
    }

}
