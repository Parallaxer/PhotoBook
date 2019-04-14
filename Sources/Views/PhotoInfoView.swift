import UIKit

final class PhotoInfoView: UIView {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!

    /// Populate the view with photo info.
    ///
    /// - Parameter photoInfo: The info to display in the view.
    func populate(withPhotoInfo photoInfo: PhotoInfo) {
        titleLabel.text = photoInfo.title
        detailLabel.text = photoInfo.detail
    }
}
