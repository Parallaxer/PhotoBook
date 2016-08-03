import UIKit

class PhotoBookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private var imageView: UIImageView!
    
    /// The image rendered in the cell.
    var image: UIImage? {
        get { return self.imageView.image }
        set { self.imageView.image = newValue }
    }
}
