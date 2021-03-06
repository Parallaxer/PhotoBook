import Parallaxer

extension PageKeyView {
    
    /// Effect which positions, sizes the slider, and rotates the view slightly around the y-axis.
    var indicateCurrentPage: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(interval: ParallaxInterval(from: 0, to: 1))
        effect.addEffect(slideEffect)
        effect.addEffect(shrinkEffect)
        effect.addEffect(rotateEffect)
        return effect
    }
    
    private var slideEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: leftPosition, to: rightPosition),
            isClamped: true,
            change: { self.sliderPosition = $0 }
        )
    }
    
    private var shrinkEffect: ParallaxEffect<CGFloat> {
        let numberOfPageTurns = Double(numberOfPages - 1)
        return ParallaxEffect(
            interval: ParallaxInterval(from: 1, to: 0.6),
            curve: .oscillate(numberOfTimes: numberOfPageTurns),
            isClamped: true,
            change: { self.sliderScale = $0 }
        )
    }
    
    private var rotateEffect: ParallaxEffect<CGFloat> {
        let rotateAmount = CGFloat.pi / 5
        return ParallaxEffect(
            interval: ParallaxInterval(from: rotateAmount, to: -rotateAmount),
            change: { self.rotation = $0 }
        )
    }
}
