import Parallaxer

extension InfinitePageKeyView {
    
    /// Effect which positions, sizes the slider, and rotates the view slightly around the y-axis.
    var indicateCurrentPage: ParallaxEffect<CGFloat> {
        var effect = ParallaxEffect<CGFloat>(interval: ParallaxInterval(from: 0, to: 1))
        effect.addEffect(slideEffect)
        effect.addEffect(shrinkEffect)
//        effect.addEffect(rotateEffect)
        return effect
    }
    
    private var slideEffect: ParallaxEffect<CGFloat> {
        var root = ParallaxEffect(
            interval: ParallaxInterval<CGFloat>(from: 0, to: 1),
            isClamped: true)
        Parallax.addDebugEffect(to: &root, named: "Slide-root")

        var slideLeftToCenter = ParallaxEffect(
            interval: ParallaxInterval(from: leftPosition, to: centerPosition),
            isClamped: true,
            change: { self.sliderPosition = $0 })
        Parallax.addDebugEffect(to: &slideLeftToCenter, named: "Slide-slideLeftToCenter")

        var slideCenterToRight = ParallaxEffect(
            interval: ParallaxInterval(from: centerPosition, to: rightPosition),
            isClamped: true,
            change: { self.sliderPosition = $0 })
        Parallax.addDebugEffect(to: &slideCenterToRight, named: "Slide-slideCenterToRight")

        let travelRatio = self.travelRatio
        root.addEffect(slideLeftToCenter, toSubinterval: ParallaxInterval(from: 0, to: travelRatio))
//        root.addEffect(slideCenterToRight, toSubinterval: ParallaxInterval(from: (1 - travelRatio), to: 1))
        return root
//        return ParallaxEffect(
//            interval: ParallaxInterval(from: leftPosition, to: rightPosition),
//            isClamped: true,
//            change: { self.sliderPosition = $0 }
//        )
    }
    
    private var shrinkEffect: ParallaxEffect<CGFloat> {
        let numberOfPageTurns = Double(numberOfPages - 1)
        return ParallaxEffect(
            interval: ParallaxInterval(from: 1, to: 0.4),
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
