import Parallaxer

extension PageKeyView {
    
    /// Effect which positions, sizes the slider, and rotates the view slightly around the y-axis.
    var indicateCurrentPage: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(over: ParallaxInterval(from: 0, to: 1))
        effect.addEffect(self.slideEffect)
        effect.addEffect(self.shrinkEffect)
        effect.addEffect(self.rotateEffect)
        return effect
    }
    
    private var slideEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect<CGFloat>(
            over:       ParallaxInterval(from: self.leftPosition, to: self.rightPosition),
            clamped:    true,
            change:     { self.sliderPosition = $0 }
        )
    }
    
    private var shrinkEffect: ParallaxEffect<CGFloat> {
        let numberOfPageTurns = Double(self.numberOfPages - 1)
        return ParallaxEffect<CGFloat>(
            over:       ParallaxInterval(from: 1, to: 0.6),
            curve:      .oscillate(numberOfTimes: numberOfPageTurns),
            clamped:    true,
            change:     { self.sliderScale = $0 }
        )
    }
    
    private var rotateEffect: ParallaxEffect<CGFloat> {
        let rotateAmount = Constants.Math.pi / 5
        return ParallaxEffect<CGFloat>(
            over:   ParallaxInterval(from: rotateAmount, to: -rotateAmount),
            change: { self.rotation = $0 }
        )
    }
}
