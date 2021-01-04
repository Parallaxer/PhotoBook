import Parallaxer
import RxCocoa
import RxSwift
import UIKit

/// Conformance allows vertical interaction to show/dismiss information about a photo.
protocol PhotoInfoAnimating: class {

    /// The interaction that will drive the photo info transition, based on a scroll view.
    var photoInfoInteractionView: UIScrollView? { get set }
    
    /// Whether the photo book can receive input.
    var photoBookInteractionEnabled: Bool { get set }
    
    /// The photo book alpha value.
    var photoBookAlpha: CGFloat { get set }
    
    /// The size of the photo book, normalized between 0 and 1.
    var photoBookScale: CGFloat { get set }
    
    /// The height of an info view, which is expected to start at the bottom of the screen.
    var photoInfoHeight: CGFloat { get set }
    
    /// Entry point for this protocol, sets up the interaction.
    func preparePhotoInfoInteraction()

    /// Bind the photo info parallax to its driving user interface elements.
    func bindPhotoInfoParallax() -> Disposable
}

extension PhotoInfoAnimating where Self: UIViewController {
    
    func preparePhotoInfoInteraction() {
        let interactionView = UIScrollView()
        interactionView.frame.size.height = view.bounds.height
        interactionView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        interactionView.isPagingEnabled = true
        interactionView.alwaysBounceHorizontal = false
        interactionView.showsVerticalScrollIndicator = false
        interactionView.showsHorizontalScrollIndicator = false
        view.addGestureRecognizer(interactionView.panGestureRecognizer)
        view.addSubview(interactionView)
        photoInfoInteractionView = interactionView
    }
}

extension PhotoInfoAnimating {

    func bindPhotoInfoParallax() -> Disposable {
        guard let interaction = photoInfoInteractionView else {
            return Disposables.create()
        }

        let photoInfoVisibility = interaction.rx.contentOffset
            .map { return $0.y }
            // Create a transform which follows the content offset over the interval of interaction.
            .parallax(over: .interval(from: 0, to: interaction.bounds.height))
            // Normalize.
            .parallaxRelate(to: ParallaxInterval<CGFloat>.rx.interval(from: 0, to: 1))
            .share()

        return Disposables.create([
            bindLockPhotoBookEffect(photoInfoVisibility: photoInfoVisibility),
            bindFadePhotoBookEffect(photoInfoVisibility: photoInfoVisibility),
            bindScalePhotoBookEffect(photoInfoVisibility: photoInfoVisibility),
            bindShowPhotoInfoEffect(photoInfoVisibility: photoInfoVisibility)
        ])
    }

    private func bindLockPhotoBookEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            .parallaxValue()
            .subscribe(onNext: { [weak self] progress in
                // While in progress, this effect prevents the user from interacting with the photo book.
                self?.photoBookInteractionEnabled = progress == CGFloat(0)
            })
    }

    private func bindFadePhotoBookEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            .parallaxRelate(to: .interval(from: 1, to: 0.75))
            .parallaxValue()
            .subscribe(onNext: { [weak self] alpha in
                self?.photoBookAlpha = alpha
            })
    }

    private func bindScalePhotoBookEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            .parallaxRelate(to: .interval(from: 1, to: 0.9))
            .parallaxValue()
            .subscribe(onNext: { [weak self] scale in
                self?.photoBookScale = scale
            })
    }
}

extension PhotoInfoAnimating {

    private func bindShowPhotoInfoEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            // Don't begin to show the photo info view until 25% of the interaction has occurred; this gives
            // the animation a sense of depth as well as priority. We want the photo book to appear to move
            // backward a little bit before the photo info view becomes visible.
            .parallaxFocus(on: .interval(from: CGFloat(0.25), to: CGFloat(1.0)))
            // Over the focus interval, increase the height from 0 to 128. In a production app, you may want
            // to use an observable height instead of a hard coded height, especially if your content varies
            // in size.
            .parallaxRelate(to: .interval(from: CGFloat(0), to: 128))
            .parallaxValue()
            .subscribe(onNext: { [weak self] height in
                self?.photoInfoHeight = height
            })
    }
}
