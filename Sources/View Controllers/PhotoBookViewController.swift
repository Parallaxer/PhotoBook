import Parallaxer
import UIKit

class PhotoBookViewController: UIViewController, PhotoInfoParallaxTransitioning {
    
    @IBOutlet private var photoBookView: PhotoBookView!
    @IBOutlet private var pageKeyView: PageKeyView!
    @IBOutlet private var photoInfoView: PhotoInfoView!
    @IBOutlet private var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteraction: ClosureBasedScrollView?
    
    var photoBookInteractionEnabled: Bool {
        get { return self.photoBookView?.isUserInteractionEnabled == true }
        set { self.photoBookView?.isUserInteractionEnabled = newValue }
    }
    
    var photoBookAlpha: CGFloat {
        get { return self.photoBookView.alpha }
        set { self.photoBookView.alpha = newValue }
    }
    
    var photoBookScale: CGFloat {
        get { return self.photoBookView.transform.a }
        set { self.photoBookView.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }
    
    var photoInfoHeight: CGFloat {
        get { return self.photoInfoHeightConstraint.constant }
        set { self.photoInfoHeightConstraint?.constant = newValue }
    }
    
    private let photos = PhotoInfo.defaultPhotos

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.photoBookView.delegate = self
        self.photoBookView.images = self.photos.map { $0.image }
        self.pageKeyView.numberOfPages = self.photos.count
        
        self.preparePhotoInfoInteraction()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updatePhotoInfoInteraction()
    }
}

extension PhotoBookViewController: PhotoBookViewDelegate {
    
    func photoBook(_ photoBookView: PhotoBookView, willSeedParallaxTree parallaxTree: inout ParallaxEffect<CGFloat>) {
        parallaxTree.addEffect(self.pageKeyView.updateProgressEffect)
    }
    
    func photoBook(_ photoBookView: PhotoBookView, didSelectPageAtIndex index: Int) {
        self.photoInfoView.populate(withPhotoInfo: self.photos[index])
    }
}
