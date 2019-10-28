import Parallaxer
import RxCocoa
import RxSwift
import UIKit

//------------------------------------------------------------------------------------------------------------
// Number of pages: 1
// Number of waypoints: 1 (min/max)
// 0
//(a)
// a
// X                    <- Left edge interval:  [nil]
// X                    <- Wrapping interval:   [nil]
// X                    <- Right edge interval: [nil]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 2
// Number of waypoints: 1
// 0 1
//(a)
//  (a)
// [ ]                  <- Left edge interval:  [0,1]
//   X                  <- Wrapping interval:   [nil]
//   X                  <- Right edge interval: [nil]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 2
// Number of waypoints: 2 (min/max)
// 0 1
//(a)b
// a(b)
// [ ]                  <- Left edge interval:  [0,1]
//   X                  <- Wrapping interval:   [nil]
//   X                  <- Right edge interval: [nil]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 3
// Number of waypoints: 3 (min/max)
// 0 1 2
//(a)b c
// a(b)c
// a b(c)
// [ ]                  <- Left edge interval:  [0,1]
//   X                  <- Wrapping interval:   [nil]
//   [ ]                <- Right edge interval: [1,2]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 4
// Number of waypoints: 3 (min)
// 0 1 2 3
//(a)b c
// a(b)c
//   b(c)a
// [ ]                  <- Left edge interval:  [0,1]
//   [ ]                <- Wrapping interval:   [1,2]
//     [ ]              <- Right edge interval: [2,3]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 5
// Number of waypoints: 3 (min)
// 0 1 2 3 4
//(a)b c
// a(b)c
// . b(c)a
// . . c(a)b
//     c a(b)
// [ ]                  <- Left edge interval:  [0,1]
//   [   ]              <- Wrapping interval:   [1,3]
//       [ ]            <- Right edge interval: [3,4]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 5
// Number of waypoints: 4
// 0 1 2 3 4
//(a)b c d
// a(b)c d
// a b(c)d
// . b c(d)a
//   b c d(a)
// [   ]                <- Left edge interval:  [0,2]
//     [ ]              <- Wrapping interval:   [2,3]
//       [ ]            <- Right edge interval: [3,4]

//------------------------------------------------------------------------------------------------------------
// Number of pages: 5
// Number of waypoints: 5 (max)
// 0 1 2 3 4
//(a)b c d e
// a(b)c d e
// a b(c)d e
// a b c(d)e
// a b c d(e)
// [   ]                <- Left edge interval:  [0,2]
//     X                <- Wrapping interval:   [nil]
//     [   ]            <- Right edge interval: [2,4]

//open class RxView: UIView {
//
//    fileprivate lazy var didLayoutSubviewsRelay = BehaviorRelay<Void>(value: ())
//
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        didLayoutSubviewsRelay.accept(())
//    }
//}
//
//extension Reactive where Base == RxView {
//
//    /// Reactive wrapper for `delegate` message.
//    public var didLayoutSubviews: Signal<Void> {
//        return base.didLayoutSubviewsRelay.asSignal(onErrorSignalWith: .never())
//    }
//}

final class InfinitePageView: UIView {

    // The total number of pages the view can represent. Set this equal to the number of pages in your table
    // view or collection view.
    @IBInspectable var numberOfPages: Int {
        get { numberOfPagesRelay.value }
        set {
            numberOfPagesRelay.accept(newValue)
            buildUI()
        }
    }
    
    /// The maximum number of waypoints shown in the view at one time. For best results, use an odd number
    /// so that the middle waypoint is rendered at the center of the view.
    @IBInspectable var maxNumberOfWaypoints: Int {
        get { maxNumberOfWaypointsRelay.value }
        set {
            maxNumberOfWaypointsRelay.accept(newValue)
            buildUI()
        }
    }

    private let numberOfPagesRelay = BehaviorRelay<Int>(value: 0)
    private let maxNumberOfWaypointsRelay = BehaviorRelay<Int>(value: 5)

    private lazy var numberOfWaypoints: Observable<Int> = Observable
        .combineLatest(
            numberOfPagesRelay.asObservable(),
            maxNumberOfWaypointsRelay.asObservable())
        .map { numberOfPages, maxNumberOfWaypoints in
            return InfinitePageView.numberOfWaypoints(
                numberOfPages: numberOfPages,
                maxNumberOfWaypoints: maxNumberOfWaypoints)
        }

    private lazy var fullPageInterval: Observable<ParallaxInterval<CGFloat>?> = numberOfPagesRelay
        .asObservable()
        .map { numberOfPages in
            let lastPageIndex = CGFloat(numberOfPages - 1)
            return ParallaxInterval<CGFloat>(from: 0, to: lastPageIndex)
        }
        .share(replay: 1)

    /// The left edge interval starts at the first page index and extends to the center waypoint index.
    ///
    /// The left edge interval may be `nil` in the following cases:
    ///   - The number of pages is 1 or less. (The center page index and the first page index are equal.)
    private lazy var leftEdgeInterval: Observable<ParallaxInterval<CGFloat>?> = Observable
        .combineLatest(
            numberOfPagesRelay.asObservable(),
            numberOfWaypoints)
        .map { numberOfPages, numberOfWaypoints -> ParallaxInterval<CGFloat>? in
            let firstPageIndex = CGFloat(0)
            let centerPageIndex =
                CGFloat(InfinitePageView.indexOfCenterWaypoint(numberOfWaypoints: numberOfWaypoints))
            return ParallaxInterval<CGFloat>(from: firstPageIndex, to: centerPageIndex)
        }
        .share(replay: 1)

    /// The wrapping interval starts where the left edge interval stopped and extends over the number of
    /// wrapped indices (the difference between the number of pages and the number of waypoints.)
    ///
    /// The wrapping interval may be `nil` in the following cases:
    ///   - The left edge interval is `nil`.
    ///   - The number of wrapped indices is 0. (The number of pages and the number of waypoints are equal.)
    private lazy var wrappingInterval: Observable<ParallaxInterval<CGFloat>?> = Observable
        .combineLatest(
            numberOfPagesRelay.asObservable(),
            numberOfWaypoints,
            leftEdgeInterval)
        .map { numberOfPages, numberOfWaypoints, leftEdgeInterval -> ParallaxInterval<CGFloat>? in
            guard let leftEdgeInterval = leftEdgeInterval else {
                return nil
            }

            let numberOfWrappedIndices = CGFloat(numberOfPages - numberOfWaypoints)
            return ParallaxInterval<CGFloat>(
                from: leftEdgeInterval.to,
                to: leftEdgeInterval.to + numberOfWrappedIndices)
        }
        .share(replay: 1)

    /// The right edge interval starts where either the wrapping interval or the left edge interval stopped
    /// and extends to the last page index.
    ///
    /// The right edge interval may be `nil` in the following cases:
    ///   - The left edge interval is `nil`.
    ///   - The left edge interval extends to the last page index.
    private lazy var rightEdgeInterval: Observable<ParallaxInterval<CGFloat>?> = Observable
        .combineLatest(
            numberOfPagesRelay.asObservable(),
            leftEdgeInterval,
            wrappingInterval)
        .map { numberOfPages, leftEdgeInterval, wrappingInterval -> ParallaxInterval<CGFloat>? in
            guard let leftEdgeInterval = leftEdgeInterval else {
                return nil
            }

            let lastPageIndex = CGFloat(numberOfPages - 1)
            return ParallaxInterval<CGFloat>(
                from: wrappingInterval?.to ?? leftEdgeInterval.to,
                to: lastPageIndex)
        }
        .share(replay: 1)

    private(set) var waypointViews: [InfinitePageView.CircleView] = []
    private weak var cursorView: InfinitePageView.CircleView?

    /// The current cursor position.
    var cursorPosition: CGFloat = 0 {
        didSet {
            let translation = CGAffineTransform(translationX: cursorPosition, y: 0)
            cursorView?.translationTransform = translation
        }
    }

    /// The current cursor size.
    var cursorScale: CGFloat = 1 {
        didSet {
            let scale = CGAffineTransform(scaleX: cursorScale, y: cursorScale)
            cursorView?.scaleTransform = scale
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let midY = bounds.midY

        let circleDiameter = self.waypointDiameter
        guard circleDiameter.isFinite else {
            return
        }

        let circleRadius = round(circleDiameter / 2)
        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)

        waypointViews.enumerated().forEach { i, circleView in
            let waypointPosition = InfinitePageView.positionForWaypoint(
                at: i,
                radius: circleRadius,
                diameter: circleDiameter)

            circleView.center = CGPoint(x: waypointPosition, y: midY)
            circleView.bounds.size = circleSize
            circleView.bounds = circleView.bounds.integral
            circleView.layer.cornerRadius = circleRadius
        }

        let cursorPosition = InfinitePageView.positionForWaypoint(
            at: 0,
            radius: circleRadius,
            diameter: circleDiameter)
        cursorView?.center = CGPoint(x: cursorPosition, y: midY)
        cursorView?.bounds.size = circleSize
        if let bounds = cursorView?.bounds.integral {
            cursorView?.bounds = bounds
        }
        cursorView?.layer.cornerRadius = circleRadius
    }

    private func buildUI() {
        cursorView?.removeFromSuperview()
        waypointViews.forEach { $0.removeFromSuperview() }

        waypointViews = (0 ..< numberOfWaypointsValue).map { _ in
            InfinitePageView.createCircleView(isWaypoint: true)
        }
        waypointViews.forEach(addSubview)

        let cursorView = InfinitePageView.createCircleView(isWaypoint: false)
        addSubview(cursorView)
        bringSubviewToFront(cursorView)
        self.cursorView = cursorView
        
        setNeedsLayout()
        layoutIfNeeded()

        // debug
//        backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
    }
}

extension InfinitePageView {

    private var waypointDiameter: CGFloat {
        return floor(bounds.width / CGFloat(numberOfWaypointsValue))
    }

    private var numberOfWaypointsValue: Int {
        return InfinitePageView.numberOfWaypoints(
            numberOfPages: numberOfPagesRelay.value,
            maxNumberOfWaypoints: maxNumberOfWaypointsRelay.value)
    }

    private var firstWaypointPosition: CGFloat {
        let diameter = self.waypointDiameter
        let radius = diameter / 2
        let index = 0
        return InfinitePageView.positionForWaypoint(at: index, radius: radius, diameter: diameter)
    }

    private var centerWaypointPosition: CGFloat {
        let diameter = self.waypointDiameter
        let radius = diameter / 2
        let index = InfinitePageView.indexOfCenterWaypoint(numberOfWaypoints: numberOfWaypointsValue)
        return InfinitePageView.positionForWaypoint(at: index, radius: radius, diameter: diameter)
    }

    private var lastWaypointPosition: CGFloat {
        let diameter = self.waypointDiameter
        let radius = diameter / 2
        let index = numberOfWaypointsValue - 1
        return InfinitePageView.positionForWaypoint(at: index, radius: radius, diameter: diameter)
    }

    private static func numberOfWaypoints(numberOfPages: Int, maxNumberOfWaypoints: Int) -> Int {
        return min(numberOfPages, maxNumberOfWaypoints)
    }

    private static func indexOfCenterWaypoint(numberOfWaypoints: Int) -> Int {
        return numberOfWaypoints / 2
    }

    private static func positionForWaypoint(at index: Int, radius: CGFloat, diameter: CGFloat) -> CGFloat {
        // Parallax animations assume that views are laid out with respect to the identity transform.
        return radius + (CGFloat(index) * diameter)
    }

    private static func distanceBetweenPages(
        atIndexA indexA: Int,
        indexB: Int,
        radius: CGFloat,
        diameter: CGFloat)
        -> CGFloat
    {
        let positionA = positionForWaypoint(at: indexA, radius: radius, diameter: diameter)
        let positionB = positionForWaypoint(at: indexB, radius: radius, diameter: diameter)
        return abs(positionB - positionA)
    }
}

extension InfinitePageView {

    private static func createCircleView(isWaypoint: Bool) -> InfinitePageView.CircleView {
        let circleView = InfinitePageView.CircleView()
        circleView.backgroundColor = isWaypoint ?  UIColor.init(white: 1, alpha: 0.5) : UIColor.white
//        circleView.backgroundColor = randomColors.randomElement()
        return circleView
    }
}

extension InfinitePageView {

    /// Bind the scrolling transform to the page view, allowing changes to the scrolling transform to drive
    /// changes to state in the page view.
    /// - Parameter scrollingTransform: The scrolling transform which should drive state changes in the page
    ///                                 view.
    func bindScrollingTransform(_ scrollingTransform: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        return Disposables.create([
            bindCursorEffect(with: scrollingTransform),
            bindWrappingEffect(with: scrollingTransform),
            bindWaypointEffect(with: scrollingTransform)
        ])
    }

    private func leftEdgeTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxScale(to: fullPageInterval.skipNil())
            .parallaxFocus(subinterval: leftEdgeInterval.skipNil())
            .parallaxReposition(with: .just(.clampToUnitInterval))
    }

    private func wrappingTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxScale(to: fullPageInterval.skipNil())
            .parallaxFocus(subinterval: wrappingInterval.skipNil())
            .parallaxReposition(with: .just(.clampToUnitInterval))
    }

    private func rightEdgeTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxScale(to: fullPageInterval.skipNil())
            .parallaxFocus(subinterval: rightEdgeInterval.skipNil())
            .parallaxReposition(with: .just(.clampToUnitInterval))
    }
}

extension InfinitePageView {

    fileprivate func bindCursorEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return Disposables.create([
            slideEffect(scrollingTransform: scrollingTransform),
            shrinkEffect(scrollingTransform: scrollingTransform)
        ])
    }

    private func slideEffect(scrollingTransform: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        let firstWaypointPosition = self.firstWaypointPosition
        let centerWaypointPosition = self.centerWaypointPosition
        let lastWaypointPosition = self.lastWaypointPosition

        let distanceFromFirstToCenter = centerWaypointPosition - firstWaypointPosition
        let firstToCenterPosition = leftEdgeTransform(from: scrollingTransform)
            .distinctUntilChanged()
            .parallaxScale(to: .interval(from: 0, to: distanceFromFirstToCenter))
            .parallaxValue()
            .debug("slideFromLeftToCenter", trimOutput: true)

        let distanceFromCenterToLast = lastWaypointPosition - centerWaypointPosition
        let centerToLastPosition = rightEdgeTransform(from: scrollingTransform)
            .distinctUntilChanged()
            .skip(1)
            .parallaxScale(to: .interval(
                from: distanceFromFirstToCenter,
                to: distanceFromFirstToCenter + distanceFromCenterToLast))
            .parallaxValue()
            .debug("slideFromCenterToRight", trimOutput: true)

        let cursorPosition = Observable
            .merge(firstToCenterPosition, centerToLastPosition)
            .distinctUntilChanged()

        return cursorPosition
            .subscribe(onNext: { [weak self] position in
                self?.cursorPosition = position
            })
    }

    private func shrinkEffect(scrollingTransform: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        let numberOfPageTurns = Double(numberOfPages - 1)
        let shrink = scrollingTransform
//            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxReposition(with: .just(.oscillate(numberOfTimes: numberOfPageTurns)))
//            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxScale(to: .interval(from: CGFloat(0.6), to: 1))
            .parallaxValue()
        return shrink
            .subscribe(onNext: { [weak self] scale in
                self?.cursorScale = scale
            })
    }
}

extension InfinitePageView {

    /// Wrapping logic:
    ///
    /// |a b c d e|
    /// |b c d e a|
    /// |c d e a b|
    /// |d e a b c|
    /// |e a b c d|
    /// |a b c d e|
    ///
    /// |• b • • •|
    /// |b • • • •|
    /// |• • • • b|
    /// |• • • b •|
    /// |• • b • •|
    /// |• b • • •|
    ///  <-------> width of all waypoints
    ///

    fileprivate func bindWrappingEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let diameter = self.waypointDiameter
        let radius = diameter / 2

        let wrappingDistanceInterval = wrappingInterval
            .map { wrappingInterval -> ParallaxInterval<CGFloat>? in
                guard let wrappingInterval = wrappingInterval else {
                    return nil
                }
                let wrappingDistance = InfinitePageView.distanceBetweenPages(
                    atIndexA: Int(wrappingInterval.from),
                    indexB: Int(wrappingInterval.to),
                    radius: radius,
                    diameter: diameter)
                return ParallaxInterval(from: 0, to: -wrappingDistance)
            }
            .skipNil()

        let wrappingTransform = self.wrappingTransform(from: scrollingTransform)
            .distinctUntilChanged()
            .parallaxScale(to: wrappingDistanceInterval)
            .parallaxValue()
            .share(replay: 1)
            .debug("wrappingTransform", trimOutput: true)

        let widthOfAllWaypoints = CGFloat(numberOfWaypointsValue) * diameter
        let disposables = waypointViews
            .enumerated()
            .map { index, waypointView -> Disposable in
                let waypointPosition = InfinitePageView.positionForWaypoint(
                    at: index,
                    radius: radius,
                    diameter: diameter)
                let distanceFromLast = (lastWaypointPosition - waypointPosition) + radius
                let waypointTranslation = wrappingTransform
                    .map { position -> CGFloat in
                        let offset = (position - distanceFromLast)
                        let remainder = offset.truncatingRemainder(
                            dividingBy: widthOfAllWaypoints) + distanceFromLast
                        return remainder
                    }
                .debug("waypointTranslation", trimOutput: false)

                return Disposables.create([
                    waypointTranslation
                        .subscribe(onNext: { position in
                            let translation = CGAffineTransform(translationX: position, y: 0)
                            waypointView.translationTransform = translation
                        })
                ])
            }
        return Disposables.create(disposables)
    }
}

extension InfinitePageView {

    fileprivate func bindWaypointEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let disposables = waypointViews
            .enumerated()
            .map { index, waypointView -> Disposable in
                let distanceSquaredBetweenWaypointAndCursor = scrollingTransform
                    .map { [weak self] _ -> CGFloat in
                        guard let self = self else {
                            return 0
                        }

                        return self.distanceSquaredFromCursor(for: waypointView)
                    }

                let firstWaypointPosition = self.firstWaypointPosition
                let centerWaypointPosition = self.centerWaypointPosition
                let halfWaypointDistance = centerWaypointPosition - firstWaypointPosition

                let cursorDistanceSquaredTransform = distanceSquaredBetweenWaypointAndCursor
                    .parallax(over: .interval(from: 0, to: halfWaypointDistance * halfWaypointDistance))

                return Disposables.create([
                    shrinkWaypoints(
                        cursorDistanceSquaredTransform: cursorDistanceSquaredTransform,
                        waypointView: waypointView),
                    fadeWaypoints(
                        cursorDistanceSquaredTransform: cursorDistanceSquaredTransform,
                        waypointView: waypointView)
                ])
            }
        return Disposables.create(disposables)
    }

    private func shrinkWaypoints(
        cursorDistanceSquaredTransform: Observable<ParallaxTransform<CGFloat>>,
        waypointView: CircleView)
        -> Disposable
    {
        let waypointScale: Observable<CGFloat> = cursorDistanceSquaredTransform
            .parallaxReposition(with: .just(.clampToUnitInterval))
//            .parallaxReposition(with: .just(.custom({ $0 * $0 })))
            .parallaxScale(to: .interval(from: CGFloat(0.6), to: 0.4))
            .parallaxValue()

        return waypointScale
            .subscribe(onNext: { scale in
                let scale = CGAffineTransform(scaleX: scale, y: scale)
                waypointView.scaleTransform = scale
            })
    }

    private func fadeWaypoints(
        cursorDistanceSquaredTransform: Observable<ParallaxTransform<CGFloat>>,
        waypointView: CircleView)
        -> Disposable
    {
        let waypointAlpha = cursorDistanceSquaredTransform
            .parallaxReposition(with: .just(.clampToUnitInterval))
//            .parallaxReposition(with: .just(.custom({ ($0 - 1) * $0 * $0 + 1 })))
            .parallaxScale(to: .interval(from: CGFloat(0.75), to: 0.5))
            .parallaxValue()

        return waypointAlpha
            .subscribe(onNext: { alpha in
                waypointView.alpha = alpha
            })
    }

    /// Calculate the squared distance between the specified subview and the cursor. This is the squared
    /// distance, which is useful for (performant) relative distance comparisons.
    ///
    /// - Parameter subview: A subview of the page key view.
    /// - Returns: The quared distance between the specified subview and the cursor.
    func distanceSquaredFromCursor(for subview: UIView) -> CGFloat {
        guard let cursorView = self.cursorView else {
            return 0
        }

        let cursorBoundsRelativeToView = cursorView.convert(cursorView.bounds, to: self)
        let subviewBoundsRelativeToView = subview.convert(subview.bounds, to: self)

        let cursorCenter = CGPoint(x: cursorBoundsRelativeToView.midX, y: cursorBoundsRelativeToView.midY)
        let subviewCenter = CGPoint(x: subviewBoundsRelativeToView.midX, y: subviewBoundsRelativeToView.midY)

        // Distance formula, without the square-root, performant way to compare relative distances.
        return pow(cursorCenter.x - subviewCenter.x, 2) + pow(cursorCenter.y - subviewCenter.y, 2)
    }
}
