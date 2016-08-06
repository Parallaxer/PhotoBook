import Parallaxer
import UIKit

/**
 Conformance adds parallax effects to photo book page changes.
 */
protocol PhotoBookParallaxing {
    
    /// The object responsible for page layout in the collection view.
    var photoBookLayout: PhotoBookCollectionViewLayout { get }
    
    /**
     Update the photo book parallax. Call this any time layout changes, or interaction occurs.
     */
    func updatePhotoBookParallax()
    
    /**
     Called just before the page-change effect is seeded, allowing effects to be nested which depend on this
     behavior.
     
     - parameter changePageEffect: The effect which is about to be seeded.
     */
    func willSeedPageChangeEffect(_ pageChangeEffect: inout ParallaxEffect<CGFloat>)
    
    /**
     Notify the conforming instance of the currently focused photo.
     
     - parameter index: Index of the photo which is currently focused.
     */
    func didShowPhoto(atIndex index: Int)
}

extension PhotoBookParallaxing {
    
    func updatePhotoBookParallax() {
        guard let collectionView = self.photoBookLayout.collectionView else {
            return
        }

        var pageChangeEffect = self.pageChangeEffect
        pageChangeEffect.addEffect(self.didShowPhotoEffect)
        self.willSeedPageChangeEffect(&pageChangeEffect)
        pageChangeEffect.seed(withValue: collectionView.contentOffset.x)
    }
    
    private var didShowPhotoEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            over:       ParallaxInterval(from: 0, to: CGFloat(self.photoBookLayout.numberOfItems - 1)),
            clamped:    true,
            change:     { self.didShowPhoto(atIndex: Int(round($0))) }
        )
    }
}
