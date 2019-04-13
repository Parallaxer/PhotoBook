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
        let indexPaths = self.photoBookLayout.collectionView?.indexPathsForVisibleItems ?? []
        let visibleCells = self.photoBookLayout.collectionView?.visibleCells ?? []
        let unitItemWidth = 1 / Double(photoBookLayout.numberOfItems - 1)

        for (indexPath, cell) in zip(indexPaths, visibleCells) {
            let itemStart = unitItemWidth * Double(indexPath.row)
            let itemEnd = itemStart + unitItemWidth
            let subinterval = ParallaxInterval(from: itemStart, to: itemEnd)
            parallaxEffect.addEffect(cell.turnPageEffect, toSubinterval: subinterval)
        }
    }
}

private extension UICollectionViewCell {
    
    var turnPageEffect: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(interval: ParallaxInterval(from: 0, to: 1))
        let spanningInterval = ParallaxInterval(from: -1.0, to: 1.0)
        effect.addEffect(self.fadeEffect, toSubinterval: spanningInterval)
        effect.addEffect(self.scaleEffect, toSubinterval: spanningInterval)
        return effect
    }
    
    var fadeEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 0.5, to: 1),
            curve: .oscillate(numberOfTimes: 1.0),
            isClamped: true,
            change: { self.alpha = $0 }
        )
    }
    
    var scaleEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 0.85, to: 1),
            curve: .oscillate(numberOfTimes: 1.0),
            isClamped: true,
            change: { self.transform = CGAffineTransform.init(scaleX: $0, y: $0) }
        )
    }
}
