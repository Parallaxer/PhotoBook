import Parallaxer
import UIKit

extension PageView {
    
    /// Effect which fades-in and scales-up a page as it enters view.
    var turnPageEffect: ParallaxEffect<CGFloat> {
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
