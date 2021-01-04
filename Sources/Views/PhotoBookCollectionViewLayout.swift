import RxCocoa
import UIKit

/// Responsible for arranging items horizontally and sizing them for paging.
final class PhotoBookCollectionViewLayout: UICollectionViewFlowLayout {

    /// Number of items currently laid out.
    var numberOfItems: Driver<Int> {
        return numberOfItemsRelay.asDriver(onErrorJustReturn: 0)
    }

    private let numberOfItemsRelay = BehaviorRelay<Int>(value: 0)

    override func prepare() {
        // Make items the same size as their collection view to support paging.
        itemSize = collectionView?.bounds.size ?? CGSize.zero
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0

        // Make items scroll horizontally.
        scrollDirection = .horizontal

        super.prepare()

        assert(collectionView?.numberOfSections == 1, "PhotoBookCollectionViewLayout expects 1 section.")

        let numberOfItems = collectionView?.numberOfItems(inSection: 0) ?? 0
        numberOfItemsRelay.accept(numberOfItems)
    }

    /// Calculate a rect describing the frame of the item at `index`.
    ///
    /// - Parameter index: Index of the item for which a rect shall be calculated.
    /// - Returns: `CGRect` describing the frame of the item at `index`.
    func rectForItem(atIndex index: Int) -> CGRect? {
        let indexPath = IndexPath(item: index, section: 0)
        let layout = layoutAttributesForItem(at: indexPath)
        return layout?.frame
    }
}
