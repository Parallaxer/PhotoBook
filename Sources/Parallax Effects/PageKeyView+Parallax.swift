import Parallaxer
import UIKit

extension PageKeyView {
    
    /// Effect which positions, sizes the slider, and rotates the view slightly around the y-axis.
    var updateProgressEffect: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(interval: ParallaxInterval(from: 0, to: 1))
        effect.addEffect(self.slideEffect)
        effect.addEffect(self.shrinkEffect)
        effect.addEffect(self.rotateEffect)
        return effect
    }
    
    private var slideEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            interval:       ParallaxInterval(from: self.leftPosition, to: self.rightPosition),
            isClamped:      true,
            onChange:       { self.sliderPosition = $0 }
        )
    }
    
    private var shrinkEffect: ParallaxEffect<CGFloat> {
        let numberOfPageTurns = Double(self.numberOfPages - 1)
        return ParallaxEffect<CGFloat>(
            interval:       ParallaxInterval(from: 1, to: 0.6),
            progressCurve:  .oscillate(numberOfTimes: numberOfPageTurns),
            isClamped:      true,
            onChange:       { self.sliderScale = $0 }
        )
    }
    
    private var rotateEffect: ParallaxEffect<CGFloat> {
        let rotateAmount = Constants.Math.pi / 5
        return ParallaxEffect<CGFloat>(
            interval:       ParallaxInterval(from: rotateAmount, to: -rotateAmount),
            onChange:       { self.rotation = $0 }
        )
    }
}
