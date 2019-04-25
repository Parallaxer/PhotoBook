import Parallaxer
import RxSwift
import RxCocoa

extension InfinitePageKeyView {

    func connect<T: ParallaxTransformable>(pageChangeProgress: Observable<T>) -> Disposable {
        // @todo: Add another circle effect for wrapping circles based on the scroll position. Each circle
        // can have its translation transform cacluated based on the scroll position.
        
        let root = pageChangeProgress.share(replay: 1)
        return Disposables.create([
            cursorViewEffect(root: root),
            travelViewEffect(root: root),
//            circleViewEffect(root: root)
        ])
    }
}

extension InfinitePageKeyView {

    fileprivate func circleViewEffect<T: ParallaxTransformable>(root: Observable<T>) -> Disposable {




        let minStepDistanceSq = pow(stepDistance, 2)
        let maxStepDistanceSq = pow(stepDistance * CGFloat(numberOfCircles / 2), 2)
        let disposables: [Disposable] = circleViews.map { circleView in
            let circleRoot = root.withLatestFrom(Observable.just(circleView))
                .map(self.distanceSquaredFromCursor(for:))
                .asParallaxObservable(over: ParallaxInterval(from: minStepDistanceSq, to: maxStepDistanceSq))
                .clampToUnitInterval()
                .share(replay: 1)

            return Disposables.create([
                alphaEffect(circleRoot: circleRoot, circleView: circleView),

                // Circles need to be contained before transformed, as their frames are
                scaleEffect(circleRoot: circleRoot, circleView: circleView)
            ])
        }

        return Disposables.create(disposables)
    }

    private func alphaEffect<T: ParallaxTransformable>(circleRoot: Observable<T>, circleView: UIView)
        -> Disposable
    {
        let alpha = circleRoot
            .transform(with: .easeInOut)
            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0))
            .parallaxValue()

        return alpha.subscribe(onNext: { circleView.alpha = $0 })
    }

    private func scaleEffect<T: ParallaxTransformable>(circleRoot: Observable<T>, circleView: UIView)
        -> Disposable
    {
        let scale = circleRoot
            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0.25))
            .parallaxValue()

        return scale.subscribe(onNext: { circleView.transform = CGAffineTransform(scaleX: $0, y: $0) })
    }
}

extension InfinitePageKeyView {

    fileprivate func cursorViewEffect<T: ParallaxTransformable>(root: Observable<T>) -> Disposable {
        return Disposables.create([
            slideEffect(root: root),
            shrinkEffect(root: root)
        ])
    }

    private func slideEffect<T: ParallaxTransformable>(root: Observable<T>) -> Disposable {
        let travelRatio = self.travelRatio
        let slideFromLeftToCenter = root
            .normalize(over: ParallaxInterval(from: 0, to: travelRatio))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval(from: leftPosition, to: centerPosition))
            .parallaxValue()
            .distinctUntilChanged()

        let slideFromCenterToRight = root
            .normalize(over: ParallaxInterval(from: (1 - travelRatio), to: 1))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval(from: centerPosition, to: rightPosition))
            .parallaxValue()
            .distinctUntilChanged()
            .skip(1)

        return Disposables.create([
            slideFromLeftToCenter.subscribe(onNext: { self.cursorPosition = $0 }),
            slideFromCenterToRight.subscribe(onNext: { self.cursorPosition = $0 })
        ])
    }

    private func shrinkEffect<T: ParallaxTransformable>(root: Observable<T>) -> Disposable {
        let numberOfPageTurns = Double(numberOfPages - 1)
        let shrink = root
            .clampToUnitInterval()
            .transform(with: .oscillate(numberOfTimes: numberOfPageTurns))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0.4))
            .parallaxValue()

        return shrink.subscribe(onNext: { self.cursorScale = $0 })
    }
}

extension InfinitePageKeyView {

    fileprivate func travelViewEffect<T: ParallaxTransformable>(root: Observable<T>) -> Disposable {
        let travelRatio = self.travelRatio
        let travelRoot = root
            .clampToUnitInterval()
            .normalize(over: ParallaxInterval(from: travelRatio, to: (1 - travelRatio)))
            .share(replay: 1)
        
        return travelSteps(travelRoot: travelRoot)
    }

    private func travelSteps<T: ParallaxTransformable>(travelRoot: Observable<T>) -> Disposable {
        let numberOfTravelSteps = CGFloat(max(numberOfPages - numberOfCircles, 0))
        let travelSteps = travelRoot
            .transform(over: ParallaxInterval<CGFloat>(from: 0, to: stepDistance * numberOfTravelSteps))
            .clampToUnitInterval()
            .parallaxValue()

        return travelSteps.subscribe(onNext: { (value) in
            self.travel = value
        })
    }
}
