import Parallaxer
import UIKit

protocol PhotoInfoParallaxTransitioning: class {
    
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
     Update the photo info interaction.
     */
    func updatePhotoInfoInteraction()
}

extension PhotoInfoParallaxTransitioning where Self: UIViewController {
    
    func preparePhotoInfoInteraction() {
        let interaction = ClosureBasedScrollView()
        interaction.frame.size.height = self.view.bounds.height
        interaction.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height * 2)
        interaction.isPagingEnabled = true
        interaction.alwaysBounceHorizontal = false
        interaction.showsVerticalScrollIndicator = false
        interaction.showsHorizontalScrollIndicator = false
        interaction.applyPanGesture(toView: self.view) { [weak self] _ in self?.updatePhotoInfoInteraction() }
        self.view.addSubview(interaction)
        self.photoInfoInteraction = interaction
    }
    
    func updatePhotoInfoInteraction() {
        guard let interaction = self.photoInfoInteraction else {
            return
        }
        
        var controller = ParallaxEffect(interval: ParallaxInterval(from: 0, to: interaction.bounds.height))
        controller.addEffect(self.focusPhotoInfoEffect)
        controller.seed(withValue: interaction.contentOffset.y)
    }
}
