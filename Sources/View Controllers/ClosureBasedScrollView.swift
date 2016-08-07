import UIKit

/**
 A scroll view which is its own delegate, and serves only to report pan interactions.
 */
class ClosureBasedScrollView: UIScrollView {
    
    private var onPan: ((scrollView: UIScrollView) -> ())?
    
    override var delegate: UIScrollViewDelegate? {
        get { return self }
        set { super.delegate = self }
    }
    
    func applyPanGesture(toView view: UIView, onPan: (scrollView: UIScrollView) -> ()) {
        self.onPan = onPan
        self.delegate = self
        view.addGestureRecognizer(self.panGestureRecognizer)
    }
}

extension ClosureBasedScrollView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.onPan?(scrollView: self)
    }
}
