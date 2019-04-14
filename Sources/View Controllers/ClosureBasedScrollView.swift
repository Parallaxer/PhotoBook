import UIKit

/// A scroll view which is its own delegate, and serves only to report pan interactions.
final class ClosureBasedScrollView: UIScrollView {
    
    fileprivate var onPan: ((_ scrollView: UIScrollView) -> ())?
    
    override var delegate: UIScrollViewDelegate? {
        get { return self }
        set { super.delegate = self }
    }
    
    func applyPanGesture(toView view: UIView, onPan: @escaping (_ scrollView: UIScrollView) -> ()) {
        self.onPan = onPan
        delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
}

extension ClosureBasedScrollView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onPan?(self)
    }
}
