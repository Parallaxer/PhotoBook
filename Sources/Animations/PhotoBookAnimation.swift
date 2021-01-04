import Parallaxer
import RxCocoa
import RxSwift
import RxSwiftExt
import UIKit

/// Animate photo cells and maintain the visible photo index as scrolling occurs.
final class PhotoBookAnimation {

    private let photoBookLayout: PhotoBookCollectionViewLayout
    private let photoBookCollectionView: UICollectionView
    
    /// Create an object responsible for animating a photo book.
    /// - Parameters:
    ///   - photoBookLayout:            The object responsible for page layout in the collection view.
    ///   - photoBookCollectionView:    The collection view in which photos are shown.
    init(photoBookLayout: PhotoBookCollectionViewLayout, photoBookCollectionView: UICollectionView) {
        self.photoBookLayout = photoBookLayout
        self.photoBookCollectionView = photoBookCollectionView
    }
}

extension PhotoBookAnimation {

    /// A parallax transform which describes the photo book's content offset in points.
    var photoBookScrollingTransform: Observable<ParallaxTransform<CGFloat>> {
        let lastItemRect = photoBookLayout.numberOfItems
            .asObservable()
            .map { [weak self] numberOfItems -> CGRect? in
                let lastItemIndex = numberOfItems - 1
                return self?.photoBookLayout.rectForItem(atIndex: lastItemIndex)
            }

        let lastItemPosition = lastItemRect
            .filterMap { rect -> FilterMap<CGFloat> in
                guard let rect = rect else {
                    return .ignore
                }

                return .map(rect.origin.x)
            }

        return photoBookCollectionView
            .rx.contentOffset
            .map { $0.x }
            .parallax(over: .interval(from: .just(0), to: lastItemPosition))
    }
}

extension PhotoBookAnimation {

    /// Output signal for the index of the currently selected photo; this changes as the user scrolls
    /// `photoBookCollectionView`
    var visiblePhotoIndex: Driver<Int> {
        let lastItemIndex = photoBookLayout.numberOfItems
            .asObservable()
            .map { CGFloat($0 - 1) }
        return photoBookScrollingTransform
            .parallaxRelate(to: .interval(from: .just(0), to: lastItemIndex))
            // Clamp to the interval so we don't miscalculate an index and cause an out-of-bounds error.
            .parallaxMorph(with: .just(.clampToUnitInterval))
            .parallaxValue()
            .map { return Int(round($0)) }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
    }

    /// Bind a parallax effect to the given `cell` which animates its alpha and scale transform as the user
    /// scrolls `photoBookCollectionView`.
    ///
    /// - Parameter cell:       The cell to animate.
    /// - Parameter indexPath:  The index path of the cell.
    /// - Returns: A subscription token.
    func bindPagingParallax(
        to cell: UICollectionViewCell,
        at indexPath: IndexPath)
        -> Disposable
    {
        let unitItemWidth = photoBookLayout.numberOfItems
            .asObservable()
            .map { numberOfItems -> CGFloat in
                guard numberOfItems > 1 else {
                    return 0
                }

                // A fully scrollable item can be scrolled off the screen; the only item which cannot do this
                // is the last item, so subtract 1.
                let numberOfFullyScrollableItems = CGFloat(numberOfItems - 1)

                // Imagine the entire width of the scroll view's content crammed between the values 0 and 1.
                // Determine the width of a single item in this proportion, assuming each item has equal width
                // and spacing.
                return 1 / numberOfFullyScrollableItems
            }

        // Determine the start and end points of the item at `itemIndex`, along the unit interval, [0, 1],
        // where it scrolls into view.
        let itemStart = unitItemWidth
            .map { $0 * CGFloat(indexPath.row) }
        let itemEnd = Observable
            .combineLatest(itemStart, unitItemWidth)
            .map { $0 + $1 }

        let pageVisibility = photoBookScrollingTransform
            // Normalize.
            .parallaxRelate(to: .interval(from: CGFloat(0), to: 1))
            // Focus only on the the portion of the interval where the item is visible on screen.
            .parallaxFocus(on: .interval(from: itemStart, to: itemEnd))
            // Normalize.
            .parallaxRelate(to: .interval(from: CGFloat(0), to: 1))
            // Expand the focus interval to encompass the item being completely off screen (-1), completely on
            // screen (0) and, finally, completely off screen on the other side (1).
            .parallaxFocus(on: .interval(from: -1, to: 1))
            // Clamp the interval so that future transformations occur only over the focused interval.
            .parallaxMorph(with: .just(.clampToUnitInterval))
            // We want to apply symmetrical visual effects as the page scrolls onto the screen from one side
            // and then scrolls off the screen from the other side.
            //
            // To accomplish the symmetrical nature of the effect, we can oscillate the transform's position
            // just once so that it moves from 0 to 1 and then back to 0 over the course of its parent
            // interval (the focused interval, [-1, 1] that we set just above).
            //
            // Thus the position shall be 1 when the item is at the center of the screen, and the position
            // shall be 0 when the item is at either edge of the screen.
            //
            // (Try changing `numberOfTimes` to 5 and see what happens when you scroll through the photos.)
            .parallaxMorph(with: .just(.oscillate(numberOfTimes: 1)))
            // Share the observable since it'll be used to drive multiple effects (fade and scale).
            .share()

        return Disposables.create([
            bindFadeEffect(to: cell, pageVisibility: pageVisibility),
            bindScaleEffect(to: cell, pageVisibility: pageVisibility)
        ])
    }

    private func bindFadeEffect(
        to cell: UICollectionViewCell,
        pageVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return pageVisibility
            // Scale down as the item visibility approaches the edge of the interval.
            .parallaxRelate(to: .interval(from: 0.5, to: 1))
            .parallaxValue()
            .subscribe(onNext: { [weak cell] alpha in
                // Change cell's alpha.
                cell?.alpha = alpha
            })
    }

    private func bindScaleEffect(
        to cell: UICollectionViewCell,
        pageVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return pageVisibility
            // Scale down as the item visibility approaches the edge of the interval.
            .parallaxRelate(to: .interval(from: 0.85, to: 1))
            .parallaxValue()
            .subscribe(onNext: { [weak cell] scale in
                // Change cell's scale.
                cell?.transform = CGAffineTransform.init(scaleX: scale, y: scale)
            })
    }
}
