import Parallaxer

extension PhotoInfoParallaxing {
    
    /// Fade out the photo book and display the photo info. While in progress, this effect prevents user
    /// interaction on the photo book.
    var showInfoEffect: ParallaxEffect<CGFloat> {
        var controller = ParallaxEffect(
            interval: ParallaxInterval(from: 0, to: 1),
            change: { self.photoBookInteractionEnabled = $0 == CGFloat(0) }
        )
        controller.addEffect(fadePhotoBookEffect)
        controller.addEffect(scalePhotoBookEffect)
        controller.addEffect(showPhotoInfoEffect, toSubinterval: ParallaxInterval(from: 0.25, to: 1.0))
        return controller
    }
    
    private var fadePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 1, to: 0.75),
            change: { self.photoBookAlpha = $0 }
        )
    }
    
    private var scalePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 1, to: 0.9),
            change: { self.photoBookScale = $0 }
        )
    }
    
    private var showPhotoInfoEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 0, to: 128),
            change: { self.photoInfoHeight = $0 }
        )
    }
}
