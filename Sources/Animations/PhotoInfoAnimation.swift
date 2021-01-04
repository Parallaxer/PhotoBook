import Parallaxer
import RxCocoa
import RxSwift
import UIKit

/// Animate photo info transition on and off screen, and lock photo book interaction while info is displayed.
final class PhotoInfoAnimation {
    
    /// Whether the photo book can receive input.
    var photoBookInteractionEnabled: Signal<Bool> {
        return photoBookInteractionEnabledRelay.asSignal()
    }
    
    /// The photo book alpha value.
    var photoBookAlpha: Signal<CGFloat> {
        return alphaRelay.asSignal()
    }
    
    /// The size of the photo book, normalized between 0 and 1.
    var photoBookScale: Signal<CGFloat> {
        return scaleRelay.asSignal()
    }
    
    /// The length of the info view drawer, which is expected to start at the bottom of the screen.
    var photoInfoDrawerLength: Signal<CGFloat> {
        return drawerLengthRelay.asSignal()
    }
    
    private let photoBookInteractionEnabledRelay = PublishRelay<Bool>()
    private let alphaRelay = PublishRelay<CGFloat>()
    private let scaleRelay = PublishRelay<CGFloat>()
    private let drawerLengthRelay = PublishRelay<CGFloat>()
    
    private let maxDrawerLength: CGFloat
    
    init(maxDrawerLength: CGFloat) {
        self.maxDrawerLength = maxDrawerLength
    }
        
    /// Bind the drawer interaction which drives the photo info animation.
    func bindDrawerInteraction(_ drawerInteraction: Observable<ParallaxTransform<CGFloat>>) -> Disposable {
        let photoInfoVisibility = drawerInteraction
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
            // While in progress, this effect prevents the user from interacting with the photo book.
            .map { $0 == CGFloat(0) }
            .bind(to: photoBookInteractionEnabledRelay)
    }

    private func bindFadePhotoBookEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            .parallaxRelate(to: .interval(from: 1, to: 0.75))
            .parallaxValue()
            .bind(to: alphaRelay)
    }

    private func bindScalePhotoBookEffect(
        photoInfoVisibility: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return photoInfoVisibility
            .parallaxRelate(to: .interval(from: 1, to: 0.9))
            .parallaxValue()
            .bind(to: scaleRelay)
    }
    
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
            .parallaxRelate(to: .interval(from: CGFloat(0), to: maxDrawerLength))
            .parallaxValue()
            .bind(to: drawerLengthRelay)
    }
}
