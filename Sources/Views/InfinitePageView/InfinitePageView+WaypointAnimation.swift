import Parallaxer
import RxSwift

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
     func bindWrappingEffect(
         with scrollingTransform: Observable<ParallaxTransform<CGFloat>>,
         wrappingInterval: Observable<ParallaxInterval<CGFloat>?>,
         wrappingTransform: Observable<ParallaxTransform<CGFloat>>)
         -> Disposable
     {
         let radius = waypointRadius
         let wrappingDistanceInterval = wrappingInterval
             .map { wrappingInterval -> ParallaxInterval<CGFloat>? in
                 guard let wrappingInterval = wrappingInterval else {
                     return nil
                 }

                 let wrappingDistance = InfinitePageView.distanceBetweenPages(
                     atIndexA: Int(wrappingInterval.from),
                     indexB: Int(wrappingInterval.to),
                     radius: radius)

                 return try ParallaxInterval(from: 0, to: -wrappingDistance)
             }
             .skipNil()

         let wrappingDistanceTransform = wrappingTransform
             .distinctUntilChanged()
             .parallaxRelate(to: wrappingDistanceInterval)
             .parallaxValue()
             .share()

         let diameter = 2 * radius
         let widthOfAllWaypoints = CGFloat(numberOfWaypointsValue) * diameter
         let disposables = waypointViews
             .enumerated()
             .map { index, waypointView -> Disposable in
                 let waypointPosition = InfinitePageView.positionForWaypoint(at: index, radius: radius)
                 let distanceFromLast = (lastWaypointPosition - waypointPosition) + radius
                 let waypointTranslation = wrappingDistanceTransform
                     .map { position -> CGFloat in
                         let offset = (position - distanceFromLast)
                         let remainder = offset.truncatingRemainder(dividingBy: widthOfAllWaypoints)
                             + distanceFromLast
                         return remainder
                     }

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

    private static func distanceBetweenPages(atIndexA indexA: Int, indexB: Int, radius: CGFloat) -> CGFloat {
        let positionA = positionForWaypoint(at: indexA, radius: radius)
        let positionB = positionForWaypoint(at: indexB, radius: radius)
        return abs(positionB - positionA)
    }
}

extension InfinitePageView {

    func bindWaypointEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let disposables = waypointViews
            .enumerated()
            .map { index, waypointView -> Disposable in
                let distanceSquaredBetweenWaypointAndCursor = scrollingTransform
                    .map { [weak self] _ -> CGFloat in
                        guard let self = self else { return 0 }
                        return self.distanceSquaredFromCursor(for: waypointView)
                    }

                let halfWaypointDistance = centerWaypointPosition - firstWaypointPosition
                let cursorDistanceSquaredTransform = distanceSquaredBetweenWaypointAndCursor
                    .parallax(over: .interval(from: 0, to: halfWaypointDistance * halfWaypointDistance))

                return Disposables.create([
                    shrinkWaypoint(
                        cursorDistanceSquaredTransform: cursorDistanceSquaredTransform,
                        waypointView: waypointView),
                    fadeWaypoint(
                        cursorDistanceSquaredTransform: cursorDistanceSquaredTransform,
                        waypointView: waypointView)
                ])
            }
        return Disposables.create(disposables)
    }

    private func shrinkWaypoint(
        cursorDistanceSquaredTransform: Observable<ParallaxTransform<CGFloat>>,
        waypointView: CircleView)
        -> Disposable
    {
        let waypointScale: Observable<CGFloat> = cursorDistanceSquaredTransform
            .parallaxMorph(with: .just(.clampToUnitInterval))
            .parallaxRelate(to: .interval(from: CGFloat(0.6), to: 0.25))
            .parallaxValue()

        return waypointScale
            .subscribe(onNext: { scale in
                let scale = CGAffineTransform(scaleX: scale, y: scale)
                waypointView.scaleTransform = scale
            })
    }

    private func fadeWaypoint(
        cursorDistanceSquaredTransform: Observable<ParallaxTransform<CGFloat>>,
        waypointView: CircleView)
        -> Disposable
    {
        let waypointAlpha = cursorDistanceSquaredTransform
            .parallaxMorph(with: .just(.clampToUnitInterval))
            .parallaxRelate(to: .interval(from: CGFloat(0.75), to: 0.5))
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
    private func distanceSquaredFromCursor(for subview: UIView) -> CGFloat {
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
