import Parallaxer
import RxSwift
import RxCocoa

extension InfinitePageKeyView {

    func connect<T: ParallaxTransformable>(pageChangeProgress: Observable<T>) -> Disposable {
        let root = pageChangeProgress
            .share(replay: 1)

        return Disposables.create([
            travelViewEffect(root: root),
            cursorViewEffect(root: root),
            circleViewEffect(root: root),
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
//                alphaEffect(circleRoot: circleRoot, circleView: circleView),
                scaleEffect(circleRoot: circleRoot, circleView: circleView)
            ])
        }

        return Disposables.create(disposables)
    }

//    private func alphaEffect<T: ParallaxTransformable>(circleRoot: Observable<T>, circleView: CircleView)
//        -> Disposable
//    {
//        let alpha = circleRoot
//            .transform(with: .easeInOut)
//            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0))
//            .parallaxValue()
//
//        return alpha.subscribe(onNext: { circleView.alpha = $0 })
//    }

    private func scaleEffect<T: ParallaxTransformable>(circleRoot: Observable<T>, circleView: CircleView)
        -> Disposable
    {
        let scale = circleRoot
            .transform(over: ParallaxInterval<CGFloat>(from: 1, to: 0.05))
            .transform(with: .custom({ $0 / 2}))
            .parallaxValue()

        return scale.subscribe(onNext: { circleView.scaleTransform = CGAffineTransform(scaleX: $0, y: $0) })
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
            .debug("slideFromLeftToCenter", trimOutput: true)

        let slideFromCenterToRight = root
            .normalize(over: ParallaxInterval(from: (1 - travelRatio), to: 1))
            .clampToUnitInterval()
            .transform(over: ParallaxInterval(from: centerPosition, to: rightPosition))
            .parallaxValue()
            .distinctUntilChanged()
            .skip(1)
            .debug("slideFromCenterToRight", trimOutput: true)

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
            .normalize(over: ParallaxInterval(from: travelRatio, to: (1 - travelRatio)))
            .clampToUnitInterval()
            .share(replay: 1)

        return Disposables.create([
            travelSteps(travelRoot: travelRoot),
            wrapCircles(travelRoot: travelRoot)
        ])
    }

    private func travelSteps<T: ParallaxTransformable>(travelRoot: Observable<T>) -> Disposable {
        let numberOfTravelSteps = CGFloat(self.numberOfTravelSteps)
        let travelSteps = travelRoot
            .transform(over: ParallaxInterval<CGFloat>(from: 0, to: stepDistance * numberOfTravelSteps))
            .clampToUnitInterval()
            .parallaxValue()

        return travelSteps.subscribe(onNext: { (value) in
            self.travel = value
        })
    }

    private func wrapCircles<T: ParallaxTransformable>(travelRoot: Observable<T>) -> Disposable {
        let numberOfCircles = self.numberOfCircles
        let numberOfTravelSteps = self.numberOfTravelSteps
        let circleOffsetsByStep = InfinitePageKeyView.calculateCircleOffsetTable(
            numberOfTravelSteps: numberOfTravelSteps + 1, // Account for the first (index 0) step.
            numberOfCircles: numberOfCircles)


        let stepDistance = self.stepDistance
        let wrapRoot = travelRoot
            .transform(over: ParallaxInterval<CGFloat>(from: 0, to: CGFloat(numberOfTravelSteps)))
            .clampToUnitInterval()
            .parallaxValue()
            .map(round)
            .map(Int.init)
            .share(replay: 1)
//            .debug("wrapRoot", trimOutput: true)

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
