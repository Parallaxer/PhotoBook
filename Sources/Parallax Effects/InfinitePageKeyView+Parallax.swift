import Parallaxer
import RxSwift
import RxSwiftExt

extension InfinitePageKeyView {

    func bindPageKeyParallax(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let normalizedScrollingTransform = scrollingTransform
            // Normalize.
            .parallaxScale(to: .interval(from: Double(0), to: 1))
            .share(replay: 1)

        return Disposables.create([
            bindCursorViewEffect(with: normalizedScrollingTransform),
            bindTravelEffect(with: scrollingTransform.map { _ in () }),
            bindTravelViewEffect(with: normalizedScrollingTransform)
        ])
    }
}

extension InfinitePageKeyView {

    fileprivate func bindTravelEffect(
        with didChange: Observable<Void>)
        -> Disposable
    {
        let minStepDistanceSq = pow(stepDistance, 2)
        let maxStepDistanceSq = pow(stepDistance * CGFloat(numberOfCircles), 2)
//        let maxStepDistanceSq = pow(stepDistance * CGFloat(numberOfCircles / 2), 2)
        let disposables: [Disposable] = circleViews.map { circleView in
            let circleRoot = didChange
                .filterMap { [weak self] _ -> FilterMap<CGFloat> in
                    guard let self = self else { return .ignore }
                    return .map(self.distanceSquaredFromCursor(for: circleView))
                }
                .parallax(over: .interval(from: CGFloat(minStepDistanceSq), to: maxStepDistanceSq))
                .parallaxReposition(with: .just(.clampToUnitInterval))
                .share(replay: 1)

            return Disposables.create([
//                alphaEffect(circleRoot: circleRoot, circleView: circleView),
                scaleEffect(circleRoot: circleRoot, circleView: circleView)
            ])
        }

        return Disposables.create(disposables)
    }

    private func alphaEffect(
        circleRoot: Observable<ParallaxTransform<CGFloat>>,
        circleView: CircleView)
        -> Disposable
    {
        let alpha = circleRoot
            .parallaxReposition(with: .just(.easeInOut))
            .parallaxScale(to: .interval(from: CGFloat(1), to: 0))
            .parallaxValue()

        return alpha.subscribe(onNext: { alpha in
            circleView.alpha = alpha
        })
    }

    private func scaleEffect(
        circleRoot: Observable<ParallaxTransform<CGFloat>>,
        circleView: CircleView)
        -> Disposable
    {
        return circleRoot
            .parallaxScale(to: .interval(from: 1, to: 0.05))
            .parallaxReposition(with: .just(.custom({ $0 / 2})))
            .parallaxValue()
            .subscribe(onNext: { scale in
                circleView.scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            })
    }
}

extension InfinitePageKeyView {

    fileprivate func bindCursorViewEffect(
        with scrollingTransform: Observable<ParallaxTransform<Double>>)
        -> Disposable
    {
        return Disposables.create([
            slideEffect(scrollingTransform: scrollingTransform),
            shrinkEffect(scrollingTransform: scrollingTransform)
        ])
    }

    private func slideEffect(scrollingTransform: Observable<ParallaxTransform<Double>>) -> Disposable {
        let travelRatio = self.travelRatio
        let slideFromLeftToCenter = scrollingTransform
            .parallaxFocus(subinterval: .interval(from: 0, to: travelRatio))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxScale(to: .interval(from: leftPosition, to: centerPosition))
            .parallaxValue()
            .distinctUntilChanged()
//            .debug("slideFromLeftToCenter", trimOutput: true)

        let slideFromCenterToRight = scrollingTransform
            .parallaxFocus(subinterval: .interval(from: (1 - travelRatio), to: 1))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxScale(to: .interval(from: centerPosition, to: rightPosition))
            .parallaxValue()
            .distinctUntilChanged()
            .skip(1)
//            .debug("slideFromCenterToRight", trimOutput: true)

        return Disposables.create([
            slideFromLeftToCenter.subscribe(onNext: { self.cursorPosition = $0 }),
            slideFromCenterToRight.subscribe(onNext: { self.cursorPosition = $0 })
        ])
    }

    private func shrinkEffect(scrollingTransform: Observable<ParallaxTransform<Double>>) -> Disposable {
        let numberOfPageTurns = Double(numberOfPages - 1)
        let shrink = scrollingTransform
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxReposition(with: .just(.oscillate(numberOfTimes: numberOfPageTurns)))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxScale(to: .interval(from: CGFloat(1), to: 0.4))
            .parallaxValue()

        return shrink.subscribe(onNext: { self.cursorScale = $0 })
    }
}

extension InfinitePageKeyView {

    fileprivate func bindTravelViewEffect(
        with scrollingTransform: Observable<ParallaxTransform<Double>>)
        -> Disposable
    {
        let travelRatio = self.travelRatio
        let travelTransform = scrollingTransform
            .parallaxFocus(subinterval: .interval(from: travelRatio, to: (1 - travelRatio)))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .share(replay: 1)

        return Disposables.create([
            travelSteps(with: travelTransform),
            wrapCircles(with: travelTransform)
        ])
    }

    private func travelSteps(
        with travelTransform: Observable<ParallaxTransform<Double>>)
        -> Disposable
    {
        let numberOfTravelSteps = CGFloat(self.numberOfTravelSteps)
        let travelSteps = travelTransform
            .parallaxScale(to: .interval(from: 0, to: stepDistance * numberOfTravelSteps))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxValue()

        return travelSteps.subscribe(onNext: { (value) in
            self.travel = value
        })
    }

    private func wrapCircles(
        with travelTransform: Observable<ParallaxTransform<Double>>)
        -> Disposable
    {
        let numberOfCircles = self.numberOfCircles
        let numberOfTravelSteps = self.numberOfTravelSteps
        let circleOffsetsByStep = InfinitePageKeyView.calculateCircleOffsetTable(
            numberOfTravelSteps: numberOfTravelSteps + 1, // Account for the first (index 0) step.
            numberOfCircles: numberOfCircles)

        let stepDistance = self.stepDistance
        let wrapRoot = travelTransform
            .parallaxScale(to: .interval(from: 0, to: CGFloat(numberOfTravelSteps)))
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxValue()
            .map(round)
            .map(Int.init)
            .share(replay: 1)

        let disposables: [Disposable] = circleViews.enumerated().map { circleIndex, circleView in
            return wrapRoot
                .subscribe(onNext: { currentStep in
                    let circleOffsets = circleOffsetsByStep[currentStep]
                    let offset = circleOffsets![circleIndex]
                    let translation = stepDistance * CGFloat(offset + currentStep)
                    let transform = CGAffineTransform(translationX: translation, y: 0)
                    circleView.translationTransform = transform
                })
        }

        return Disposables.create(disposables)
    }
}

extension InfinitePageKeyView {

    /// Calculate the circle offset table, storing each row in a dictionary keyed by the step count.
    ///
    /// - Parameters:
    ///   - numberOfTravelSteps:    Number of wrapping steps necessary to visit every page.
    ///   - numberOfCircles:        Number of circles visible in the view.
    /// - Returns: A dictionary consisting of circle offset arrays, keyed by step count.
    fileprivate static func calculateCircleOffsetTable(numberOfTravelSteps: Int, numberOfCircles: Int)
        -> [Int: [Int]]
    {
        // circleOffsetsByStep: [currentStep: [offsets by visible thing]]
        // [
        //     0: [0, 2, 1]
        //     1: [1, 0, 2]
        //     2: [2, 1, 0]
        // ]

        let circleOffsets: [Int] = (0 ..< numberOfCircles).reversed()
        let steps = Array(0 ..< numberOfTravelSteps)
        let circleOffsetTable = steps.map { step in
            return circleOffsets.map { circleOffset in
                return (circleOffset + step + (numberOfCircles + 1)) % numberOfCircles
            }
        }

        return Dictionary(uniqueKeysWithValues: zip(steps, circleOffsetTable))
    }
}
