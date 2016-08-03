import Parallaxer
import UIKit

/**
 Conformance allows vertical interaction to show/dismiss information about a photo.
 */
protocol PhotoInfoParallaxing: class {
    
    /// The interaction that will drive the photo info transition, based on a scroll view.
    var photoInfoInteraction: ClosureBasedScrollView? { get set }
    
    /// Whether the photo book can receive input.
    var photoBookInteractionEnabled: Bool { get set }
    
    /// The photo book alpha value.
    var photoBookAlpha: CGFloat { get set }
    
    /// The size of the photo book, normalized between 0 an 1.
    var photoBookScale: CGFloat { get set }
    
    /// The height of an info view, which is expected to start at the bottom of the screen.
    var photoInfoHeight: CGFloat { get set }
    
    /**
     Entry point for this protocol, sets up the interaction.
     */
    func preparePhotoInfoInteraction()
    
    /**
     Update the photo info parallax. Call this any time layout changes, or interaction occurs.
     */
    func updatePhotoInfoParallax()
}

extension PhotoInfoParallaxing where Self: UIViewController {
    
    func preparePhotoInfoInteraction() {
        let interaction = ClosureBasedScrollView()
        interaction.frame.size.height = self.view.bounds.height
        interaction.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height * 2)
        interaction.isPagingEnabled = true
        interaction.alwaysBounceHorizontal = false
        interaction.showsVerticalScrollIndicator = false
        interaction.showsHorizontalScrollIndicator = false
        interaction.applyPanGesture(toView: self.view) { [weak self] _ in self?.updatePhotoInfoParallax() }
        self.view.addSubview(interaction)
        self.photoInfoInteraction = interaction
    }
    
    func updatePhotoInfoParallax() {
        guard let interaction = self.photoInfoInteraction else {
            return
        }
        
        var controller = ParallaxEffect(interval: ParallaxInterval(from: 0, to: interaction.bounds.height))
        controller.addEffect(self.showInfoEffect)
        controller.seed(withValue: interaction.contentOffset.y)
    }
}
