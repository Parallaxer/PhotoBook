import Parallaxer
import RxSwift
import RxCocoa

extension InfinitePageKeyView {

    func connect<T: ParallaxTransformable>(pageChangeProgress: Observable<T>) -> [Disposable] {
        let root = pageChangeProgress.share(replay: 1)
        return slideEffect(root: root)
            + shrinkEffect(root: root)
    }

    private func shrinkEffect<T: ParallaxTransformable>(root: Observable<T>) -> [Disposable] {
        let numberOfPageTurns = Double(numberOfPages - 1)
        let shrink = root
            .transform(with: .oscillate(numberOfTimes: numberOfPageTurns))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0.4))
            .parallaxValue()

        return [
            shrink.subscribe(onNext: { self.sliderScale = $0 })
        ]
    }

    private func slideEffect<T: ParallaxTransformable>(root: Observable<T>) -> [Disposable] {
        let slideLeftToCenter = root
            .normalize(over: ParallaxInterval(from: 0, to: travelRatio))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval(from: leftPosition, to: centerPosition))
            .parallaxValue()
            .distinctUntilChanged()

        let slideCenterToRight = root
            .normalize(over: ParallaxInterval(from: (1 - travelRatio), to: 1))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval(from: centerPosition, to: rightPosition))
            .parallaxValue()
            .distinctUntilChanged()
            .skip(1)

        return [
            slideLeftToCenter.subscribe(onNext: { self.sliderPosition = $0 }),
            slideCenterToRight.subscribe(onNext: { self.sliderPosition = $0 }),
        ]
    }
}
