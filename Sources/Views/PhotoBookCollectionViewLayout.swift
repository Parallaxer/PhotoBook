import Parallaxer
import RxCocoa
import UIKit

final class PhotoBookCollectionViewLayout: UICollectionViewLayout {

    /// Number of items currently laid out.
    var numberOfItems: Driver<Int> {
        return itemAttributesRelay
            .asObservable()
            .map { return $0.count }
            .asDriver(onErrorJustReturn: 0)
    }

    private let itemAttributesRelay = BehaviorRelay<[UICollectionViewLayoutAttributes]>(value: [])
    private var contentSize: CGSize?

    override var collectionViewContentSize: CGSize {
        return contentSize ?? CGSize.zero
    }

    override func prepare() {
        super.prepare()

        assert(collectionView?.numberOfSections == 1,
               "PhotoBookCollectionViewLayout requires 1 section.")

        let numberOfItems = collectionView?.numberOfItems(inSection: 0) ?? 0
        let lastItemFrame = rectForItem(atIndex: numberOfItems - 1)
        contentSize = CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)

        let attributes: [UICollectionViewLayoutAttributes] = (0 ..< numberOfItems).map { index in
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
            attributes.frame = rectForItem(atIndex: index)
            return attributes
        }

        itemAttributesRelay.accept(attributes)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemAttributesRelay.value.filter { rect.intersects($0.frame) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let numberOfItems = itemAttributesRelay.value.count
        if indexPath.row >= numberOfItems {
            return nil
        }

        return itemAttributesRelay.value[indexPath.row]
    }

    /// Calculate a rect describing the frame of the item at `index`.
    ///
    /// - Parameter index: Index of the item for which a rect shall be calculated.
    /// - Returns: `CGRect` describing the frame of the item at `index`.
    func rectForItem(atIndex index: Int) -> CGRect {
        guard let itemSize = collectionView?.bounds.size else {
            return CGRect.zero
        }

        let offset = CGFloat(index) * itemSize.width
        return CGRect(origin: CGPoint(x: offset, y: 0), size: itemSize)
    }
}
