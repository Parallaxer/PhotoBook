import UIKit

extension InfinitePageView {

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
}
