import Parallaxer
import UIKit

/// Conformance adds parallax effects to photo book page changes.
protocol PhotoBookParallaxing {
    
    /// The object responsible for page layout in the collection view.
    var photoBookLayout: PhotoBookCollectionViewLayout { get }
    
    /// Update the photo book parallax. Call this any time layout changes, or interaction occurs.
    func updatePhotoBookParallax()

    /// DescriptionCalled just before the page-change effect is seeded, allowing effects to be nested which depend on this
    /// behavior.
    ///
    /// - Parameter pageChangeEffect: The effect which is about to be seeded.
    func willSeedPageChangeEffect(_ pageChangeEffect: inout ParallaxEffect<CGFloat>)
    
    /// Notify the conforming instance of the currently focused photo.
    ///
    /// - Parameter index: Index of the photo which is currently focused.
    func didShowPhoto(atIndex index: Int)
}

extension PhotoBookParallaxing {
    
    func updatePhotoBookParallax() {
        guard let collectionView = photoBookLayout.collectionView else {
            return
        }

        var pageChangeEffect = self.pageChangeEffect
        pageChangeEffect.addEffect(didShowPhotoEffect)
        willSeedPageChangeEffect(&pageChangeEffect)
        pageChangeEffect.seed(withValue: collectionView.contentOffset.x)
    }
    
    private var didShowPhotoEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 0, to: CGFloat(photoBookLayout.numberOfItems - 1)),
            isClamped: true,
            change: { self.didShowPhoto(atIndex: Int(round($0))) }
        )
    }
}
