import UIKit

final class PhotoBookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private var imageView: UIImageView!
    
    /// The image rendered in the cell.
    var image: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }
}
