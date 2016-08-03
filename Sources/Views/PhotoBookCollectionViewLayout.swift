import Parallaxer
import UIKit

class PhotoBookCollectionViewLayout: UICollectionViewLayout {
    
    /// Number of items currently laid out.
    var numberOfItems: Int {
        return self.itemAttributes.count
    }
    
    private var itemAttributes = [UICollectionViewLayoutAttributes]()
    private var contentSize: CGSize?
    
    override func collectionViewContentSize() -> CGSize {
        return self.contentSize ?? CGSize.zero
    }
    
    override func prepare() {
        super.prepare()
        
        assert(self.collectionView?.numberOfSections() == 1,
               "PhotoBookCollectionViewLayout requires 1 section.")
        
        let numberOfItems = self.collectionView?.numberOfItems(inSection: 0) ?? 0
        let lastItemFrame = self.rectForItem(atIndex: numberOfItems - 1)
        self.contentSize = CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)
        
        self.itemAttributes = (0 ..< numberOfItems).map { index in
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
            attributes.frame = self.rectForItem(atIndex: index)
            return attributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.itemAttributes.filter { rect.intersects($0.frame) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.row >= self.numberOfItems {
            return nil
        }

        return self.itemAttributes[indexPath.row]
    }
    
    /**
     Calculate a rect describing the frame of the item at `index`.
     
     - parameter index: Index of the item for which a rect shall be calculated.
     
     - returns: `CGRect` describing the frame of the item at `index`.
     */
    func rectForItem(atIndex index: Int) -> CGRect {
        guard let itemSize = self.collectionView?.bounds.size else {
            return CGRect.zero
        }
        
        let offset = CGFloat(index) * itemSize.width
        return CGRect(origin: CGPoint(x: offset, y: 0), size: itemSize)
    }
}
