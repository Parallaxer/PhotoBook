import RxSwift
import UIKit

/// Responsible for rendering a single photo in a photo book.
final class PhotoBookCollectionViewCell: UICollectionViewCell {

    /// The image rendered in the cell.
    var image: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }

    /// Cell-related subscription tokens should be stored here so they may be disposed of upon cell reuse.
    private(set) var disposeBag = DisposeBag()

    @IBOutlet private var imageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
