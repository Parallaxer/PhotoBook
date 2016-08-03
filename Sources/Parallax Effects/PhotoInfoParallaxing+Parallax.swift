import Parallaxer
import UIKit

extension PhotoInfoParallaxing {
    
    /// Fade out the photo book and display the photo info. While in progress, this effect prevents user
    /// interaction on the photo book.
    var showInfoEffect: ParallaxEffect<CGFloat> {
        var controller = ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 0, to: 1),
            onChange: { self.photoBookInteractionEnabled = $0 == 0 }
        )
        controller.addEffect(self.fadePhotoBookEffect)
        controller.addEffect(self.scalePhotoBookEffect)
        controller.addEffect(self.showPhotoInfoEffect, subinterval: ParallaxInterval(from: 0.25, to: 1.0))
        return controller
    }
    
    private var fadePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 1, to: 0.75),
            onChange: { self.photoBookAlpha = $0 }
        )
    }
    
    private var scalePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 1, to: 0.9),
            onChange: { self.photoBookScale = $0 }
        )
    }
    
    private var showPhotoInfoEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 0, to: 128),
            onChange: { self.photoInfoHeight = $0 }
        )
    }
}
