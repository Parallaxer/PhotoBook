import Parallaxer
import RxSwift

extension PageKeyView {

    func bindPageKeyParallax(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let normalizedScrollingTransform = scrollingTransform
            .parallaxScale(to: .interval(from: CGFloat(0), to: 1))

        return Disposables.create([
            bindSlideEffect(with: normalizedScrollingTransform),
            bindShrinkEffect(with: normalizedScrollingTransform),
            bindRotateEffect(with: normalizedScrollingTransform)
        ])
    }

    private func bindSlideEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        return scrollingTransform
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxScale(to: .interval(from: leftPosition, to: rightPosition))
            .parallaxValue()
            .subscribe(onNext: { [weak self] position in
                self?.sliderPosition = position
            })
    }

    private func bindShrinkEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let numberOfPageTurns = Double(numberOfPages - 1)
        return scrollingTransform
            .parallaxReposition(with: .just(.clampToUnitInterval))
            .parallaxReposition(with: .just(.oscillate(numberOfTimes: numberOfPageTurns)))
            .parallaxScale(to: .interval(from: 1, to: 0.4))
            .parallaxValue()
            .subscribe(onNext: { [weak self] scale in
                self?.sliderScale = scale
            })
    }

    private func bindRotateEffect(
        with scrollingTransform: Observable<ParallaxTransform<CGFloat>>)
        -> Disposable
    {
        let rotateAmount = CGFloat.pi / 5
        return scrollingTransform
            .parallaxScale(to: .interval(from: rotateAmount, to: -rotateAmount))
            .parallaxValue()
            .subscribe(onNext: { [weak self] rotation in
                self?.rotation = rotation
            })
    }
}
