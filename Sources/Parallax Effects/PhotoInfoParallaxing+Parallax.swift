import Parallaxer

extension PhotoInfoParallaxing {
    
    /// Fade out the photo book and display the photo info. While in progress, this effect prevents user
    /// interaction on the photo book.
    var showInfoEffect: ParallaxEffect<CGFloat> {
        var controller = ParallaxEffect<CGFloat>(
            over:   ParallaxInterval(from: 0, to: 1),
            change: { self.photoBookInteractionEnabled = $0 == 0 }
        )
        controller.addEffect(self.fadePhotoBookEffect)
        controller.addEffect(self.scalePhotoBookEffect)
        controller.addEffect(self.showPhotoInfoEffect, toSubinterval: ParallaxInterval(from: 0.25, to: 1.0))
        return controller
    }
    
    private var fadePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            over:   ParallaxInterval(from: 1, to: 0.75),
            change: { self.photoBookAlpha = $0 }
        )
    }
    
    private var scalePhotoBookEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            over:   ParallaxInterval(from: 1, to: 0.9),
            change: { self.photoBookScale = $0 }
        )
    }
    
    private var showPhotoInfoEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            over:   ParallaxInterval(from: 0, to: 128),
            change: { self.photoInfoHeight = $0 }
        )
    }
}
