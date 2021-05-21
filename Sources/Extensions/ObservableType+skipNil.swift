import RxSwift

extension ObservableType where Element: OptionalType {
    /// Skip nil signals. `Element` becomes non-optional.
    public func skipNil() -> Observable<Element.WrappedType> {
        return flatMap { element -> Observable<Element.WrappedType> in
            return element.asOptional.map(Observable.just) ?? .empty()
        }
    }
}

extension ObservableType {
    public func asOptional() -> Observable<Element?> {
        return map { element in
            return element
        }
    }
}
