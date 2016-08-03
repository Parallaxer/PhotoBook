import Parallaxer
import UIKit


extension PhotoBookParallaxing {
    
    /// Parallax effect that follows page changes in the photo book.
    var pageChangeEffect: ParallaxEffect<CGFloat> {
        let numberOfItems = self.photoBookLayout.numberOfItems
        let lastItemPosition = self.photoBookLayout.rectForItem(atIndex: numberOfItems - 1).origin.x
        var root = ParallaxEffect(interval: ParallaxInterval(from: 0, to: lastItemPosition))
        self.addEffectsForVisibleCells(to: &root)
        return root
    }
    
    private func addEffectsForVisibleCells(to parallaxEffect: inout ParallaxEffect<CGFloat>) {
        let indexPaths = self.photoBookLayout.collectionView?.indexPathsForVisibleItems() ?? []
        let visibleCells = self.photoBookLayout.collectionView?.visibleCells() ?? []
        let unitItemWidth = 1 / Double(photoBookLayout.numberOfItems - 1)

        for (indexPath, cell) in zip(indexPaths, visibleCells) {
            let itemStart = unitItemWidth * Double(indexPath.row)
            let itemEnd = itemStart + unitItemWidth
            let subinterval = ParallaxInterval(from: itemStart, to: itemEnd)
            parallaxEffect.addEffect(cell.turnPageEffect, subinterval: subinterval)
        }
    }
}

private extension UICollectionViewCell {
    
    private var turnPageEffect: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(interval: ParallaxInterval(from: 0, to: 1))
        let spanningInterval = ParallaxInterval(from: -1.0, to: 1.0)
        effect.addEffect(self.fadeEffect, subinterval: spanningInterval)
        effect.addEffect(self.scaleEffect, subinterval: spanningInterval)
        return effect
    }
    
    private var fadeEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval:       ParallaxInterval(from: 0.5, to: 1),
            progressCurve:  .oscillate(numberOfTimes: 1.0),
            isClamped:      true,
            onChange:       { self.alpha = $0 }
        )
    }
    
    private var scaleEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval:       ParallaxInterval(from: 0.85, to: 1),
            progressCurve:  .oscillate(numberOfTimes: 1.0),
            isClamped:      true,
            onChange:       { self.transform = CGAffineTransform.init(scaleX: $0, y: $0) }
        )
    }
}