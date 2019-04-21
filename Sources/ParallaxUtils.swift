import Parallaxer

// TESTING:
// Consider replacing ParallaxEffect.change with an observable.
//extension ParallaxEffect {
//
//    func asObservable() -> Observable<ValueType> {
//        let subject = PublishSubject<ValueType>()
//        change = { value in
//            subject.on(.next(value))
//        }
//        return subject
//    }
//}

struct Parallax {

    /// Debug an effect by ensuring its interval behaves as expected.
    ///
    /// - Parameters:
    ///   - effect:     The effect to debug.
    ///   - debugName:  The name to print out with the debug info.
    static func addDebugEffect<T>(to effect: inout ParallaxEffect<T>,
                                  named debugName: String = "unnamed")
    {
        #if DEBUG
        let percentEffect = ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 0, to: 100),
            change: { value in
                print("DEBUG EFFECT (\(debugName)): \(Int(value))%")
        })

        effect.addEffect(percentEffect)
        #endif
    }
}
