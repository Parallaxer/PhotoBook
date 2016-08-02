import UIKit

class PhotoInfoView: UIView {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    
    /**
     Populate the view with photo info.
     
     - parameter photoInfo: The info to display in the view.
     */
    func populate(withPhotoInfo photoInfo: PhotoInfo) {
        self.titleLabel.text = photoInfo.title
        self.detailLabel.text = photoInfo.detail
    }
}
