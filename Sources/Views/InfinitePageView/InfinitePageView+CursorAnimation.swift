import Parallaxer
import RxSwift

extension InfinitePageView {

    func bindCursorEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>,
        leftEdgeTransform: Observable<ParallaxTransform<CGFloat>>,
        rightEdgeTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return Disposables.create([
            slideEffect(
                scrollingTransform: scrollingTransform,
                leftEdgeTransform: leftEdgeTransform,
                rightEdgeTransform: rightEdgeTransform),
            growEffect(scrollingTransform: scrollingTransform)
        ])
    }

    private func slideEffect(
        scrollingTransform: Observable<ParallaxTransform<CGFloat>>,
        leftEdgeTransform: Observable<ParallaxTransform<CGFloat>>,
        rightEdgeTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let centerWaypointPosition = self.centerWaypointPosition
        let lastWaypointPosition = self.lastWaypointPosition

        let distanceFromFirstToCenter = centerWaypointPosition - firstWaypointPosition
        let firstToCenterPosition = leftEdgeTransform
            .distinctUntilChanged()
            .parallaxRelate(to: .interval(from: 0, to: distanceFromFirstToCenter))
            .parallaxValue()

        let distanceFromCenterToLast = lastWaypointPosition - centerWaypointPosition
        let centerToLastPosition = rightEdgeTransform
            .distinctUntilChanged()
            .skip(1)
            .parallaxRelate(to: .interval(
                from: distanceFromFirstToCenter,
                to: distanceFromFirstToCenter + distanceFromCenterToLast))
            .parallaxValue()

        let cursorPosition = Observable
            .merge(firstToCenterPosition, centerToLastPosition)
            .distinctUntilChanged()

        return cursorPosition
            .subscribe(onNext: { [weak self] position in
                self?.cursorPosition = position
            })
    }

    private func growEffect(scrollingTransform: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        let numberOfPageTurns = Double(numberOfPages - 1)
        let shrink = scrollingTransform
            .parallaxMorph(with: .just(.oscillate(numberOfTimes: numberOfPageTurns)))
            .parallaxRelate(to: .interval(from: CGFloat(0.6), to: 1))
            .parallaxValue()
        return shrink
            .subscribe(onNext: { [weak self] scale in
                self?.cursorScale = scale
            })
    }
}
