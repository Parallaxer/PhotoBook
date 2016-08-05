import Parallaxer
import UIKit

private let kPhotoBookCellID = "PhotoBookCell"

class PhotoBookViewController: UIViewController {
    
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var pageKeyView: PageKeyView!
    @IBOutlet private var photoInfoView: PhotoInfoView!
    @IBOutlet private var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteraction: ClosureBasedScrollView?
    
    private let photos = PhotoInfo.defaultPhotos
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageKeyView.numberOfPages = self.photos.count
        self.collectionView.reloadData()

        self.preparePhotoInfoInteraction()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updatePhotoInfoParallax()
        self.updatePhotoBookParallax()
    }
}

extension PhotoBookViewController: PhotoInfoParallaxing {
    
    var photoBookInteractionEnabled: Bool {
        get { return self.collectionView.isUserInteractionEnabled == true }
        set { self.collectionView.isUserInteractionEnabled = newValue }
    }
    
    var photoBookAlpha: CGFloat {
        get { return self.collectionView.alpha }
        set { self.collectionView.alpha = newValue }
    }
    
    var photoBookScale: CGFloat {
        get { return self.collectionView.transform.a }
        set { self.collectionView.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }
    
    var photoInfoHeight: CGFloat {
        get { return self.photoInfoHeightConstraint.constant }
        set { self.photoInfoHeightConstraint?.constant = newValue }
    }
}

extension PhotoBookViewController: PhotoBookParallaxing {
    
    var photoBookLayout: PhotoBookCollectionViewLayout {
        return self.collectionView.collectionViewLayout as! PhotoBookCollectionViewLayout
    }
    
    func willSeedPageChangeEffect(_ pageChangeEffect: inout ParallaxEffect<CGFloat>) {
        pageChangeEffect.addEffect(self.pageKeyView.indicateCurrentPage)
    }
    
    func didShowPhoto(atIndex index: Int) {
        self.photoInfoView.populate(withPhotoInfo: self.photos[index])
    }
}

extension PhotoBookViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kPhotoBookCellID, for: indexPath)
        (cell as? PhotoBookCollectionViewCell)?.image = self.photos[indexPath.row].image
        return cell
    }
}

extension PhotoBookViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updatePhotoBookParallax()
    }
}
