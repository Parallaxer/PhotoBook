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

/// Used for the "cursor" and "waypoint" views in an `InfinitePageView`.
final class CircleView: UIView {

    /// The circle's scale transform.
    var scaleTransform: CGAffineTransform = .identity {
        didSet { updateTransform() }
    }

    /// The circle's translation transform.
    var translationTransform: CGAffineTransform = .identity {
        didSet { updateTransform() }
    }

    private func updateTransform() {
        transform = scaleTransform.concatenating(translationTransform)
    }
}

@IBDesignable
public final class InfinitePageView: UIView {

    // The total number of pages the view can represent. Set this equal to the number of pages in your table
    // view or collection view.
    @IBInspectable
    public var numberOfPages: Int {
        get { numberOfPagesRelay.value }
        set {
            numberOfPagesRelay.accept(newValue)
            buildUI()
        }
    }
    
    /// The maximum number of waypoints shown in the view at one time. For best results, use an odd number
    /// so that the middle waypoint is rendered at the center of the view.
    @IBInspectable
    public var maxNumberOfWaypoints: Int {
        get { maxNumberOfWaypointsRelay.value }
        set {
            maxNumberOfWaypointsRelay.accept(newValue)
            buildUI()
        }
    }

    private(set) var waypointViews: [CircleView] = []
    private(set) weak var cursorView: CircleView?

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
            return try ParallaxInterval<CGFloat>(from: 0, to: lastPageIndex)
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
            return try ParallaxInterval<CGFloat>(from: firstPageIndex, to: centerPageIndex)
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
            return try ParallaxInterval<CGFloat>(
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
            return try ParallaxInterval<CGFloat>(
                from: wrappingInterval?.to ?? leftEdgeInterval.to,
                to: lastPageIndex)
        }
        .share(replay: 1)

    public override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let circleRadius = waypointRadius
        guard circleRadius.isFinite else {
            return
        }

        let circleDiameter = 2 * circleRadius
        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)
        let midY = bounds.midY

        waypointViews.enumerated().forEach { i, circleView in
            let waypointPosition = InfinitePageView.positionForWaypoint(at: i, radius: circleRadius)
            circleView.center = CGPoint(x: waypointPosition, y: midY)
            circleView.bounds.size = circleSize
            circleView.bounds = circleView.bounds.integral
            circleView.layer.cornerRadius = circleRadius
        }

        let cursorPosition = InfinitePageView.positionForWaypoint(at: 0, radius: circleRadius)
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

        // Force immediate layout.
        setNeedsLayout()
        layoutIfNeeded()
    }

    private static func createCircleView(isWaypoint: Bool) -> CircleView {
        let circleView = CircleView()
        circleView.backgroundColor = isWaypoint ?  UIColor.init(white: 1, alpha: 0.5) : UIColor.white
        return circleView
    }
}

extension InfinitePageView {

    /// Bind the scrolling transform to the page view, allowing changes to the scrolling transform to drive
    /// changes to state in the page view.
    /// - Parameter scrollingTransform: The scrolling transform which should drive state changes in the page
    ///                                 view.
    func bindScrollingTransform(_ scrollingTransform: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        let leftEdgeTransform = self.leftEdgeTransform(from: scrollingTransform)
        let rightEdgeTransform = self.rightEdgeTransform(from: scrollingTransform)
        let wrappingTransform = self.wrappingTransform(from: scrollingTransform)
        return Disposables.create([
            bindCursorEffect(
                with: scrollingTransform,
                leftEdgeTransform: leftEdgeTransform,
                rightEdgeTransform: rightEdgeTransform),
            bindWrappingEffect(
                with: scrollingTransform,
                wrappingInterval: wrappingInterval,
                wrappingTransform: wrappingTransform),
            bindWaypointEffect(with: scrollingTransform)
        ])
    }

    private func leftEdgeTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxRelate(to: fullPageInterval.skipNil())
            .parallaxFocus(on: leftEdgeInterval.skipNil())
            .parallaxMorph(with: .just(.clampToUnitInterval))
    }

    private func wrappingTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxRelate(to: fullPageInterval.skipNil())
            .parallaxFocus(on: wrappingInterval.skipNil())
            .parallaxMorph(with: .just(.clampToUnitInterval))
    }

    private func rightEdgeTransform(
        from scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Observable<ParallaxTransform<CGFloat>>
    {
        return scrollingTransform
            .parallaxRelate(to: fullPageInterval.skipNil())
            .parallaxFocus(on: rightEdgeInterval.skipNil())
            .parallaxMorph(with: .just(.clampToUnitInterval))
    }
}

extension InfinitePageView {

    var waypointRadius: CGFloat {
        let diameter = floor(bounds.width / CGFloat(numberOfWaypointsValue))
        return floor(diameter / 2)
    }

    var numberOfWaypointsValue: Int {
        return InfinitePageView.numberOfWaypoints(
            numberOfPages: numberOfPagesRelay.value,
            maxNumberOfWaypoints: maxNumberOfWaypointsRelay.value)
    }
}

extension InfinitePageView {

    var firstWaypointPosition: CGFloat {
        let firstIndex = 0
        return InfinitePageView.positionForWaypoint(at: firstIndex, radius: waypointRadius)
    }

    var centerWaypointPosition: CGFloat {
        let centerIndex = InfinitePageView.indexOfCenterWaypoint(numberOfWaypoints: numberOfWaypointsValue)
        return InfinitePageView.positionForWaypoint(at: centerIndex, radius: waypointRadius)
    }

    var lastWaypointPosition: CGFloat {
        let lastIndex = numberOfWaypointsValue - 1
        return InfinitePageView.positionForWaypoint(at: lastIndex, radius: waypointRadius)
    }

    static func numberOfWaypoints(numberOfPages: Int, maxNumberOfWaypoints: Int) -> Int {
        return min(numberOfPages, maxNumberOfWaypoints)
    }

    private static func indexOfCenterWaypoint(numberOfWaypoints: Int) -> Int {
        return numberOfWaypoints / 2
    }

    static func positionForWaypoint(at index: Int, radius: CGFloat) -> CGFloat {
        let diameter = 2 * radius
        return radius + (CGFloat(index) * (diameter))
    }
}
