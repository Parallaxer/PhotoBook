import Parallaxer
import UIKit

private let kPhotoBookCellID = "PhotoBookCell"

final class PhotoBookViewController: UIViewController {
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var pageKeyView: PageKeyView!
    @IBOutlet fileprivate var photoInfoView: PhotoInfoView!
    @IBOutlet fileprivate var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteraction: ClosureBasedScrollView?
    
    fileprivate let photos = PhotoInfo.defaultPhotos
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageKeyView.numberOfPages = photos.count
        collectionView.reloadData()

        preparePhotoInfoInteraction()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePhotoInfoParallax()
        updatePhotoBookParallax()
    }
}

extension PhotoBookViewController: PhotoInfoParallaxing {
    
    var photoBookInteractionEnabled: Bool {
        get { return collectionView.isUserInteractionEnabled == true }
        set { collectionView.isUserInteractionEnabled = newValue }
    }
    
    var photoBookAlpha: CGFloat {
        get { return collectionView.alpha }
        set { collectionView.alpha = newValue }
    }
    
    var photoBookScale: CGFloat {
        get { return collectionView.transform.a }
        set { collectionView.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }
    
    var photoInfoHeight: CGFloat {
        get { return photoInfoHeightConstraint.constant }
        set { photoInfoHeightConstraint?.constant = newValue }
    }
}

extension PhotoBookViewController: PhotoBookParallaxing {
    
    var photoBookLayout: PhotoBookCollectionViewLayout {
        return collectionView.collectionViewLayout as! PhotoBookCollectionViewLayout
    }
    
    func willSeedPageChangeEffect(_ pageChangeEffect: inout ParallaxEffect<CGFloat>) {
        pageChangeEffect.addEffect(pageKeyView.indicateCurrentPage)
    }
    
    func didShowPhoto(atIndex index: Int) {
        photoInfoView.populate(withPhotoInfo: photos[index])
    }
}

extension PhotoBookViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kPhotoBookCellID, for: indexPath)
        (cell as? PhotoBookCollectionViewCell)?.image = photos[indexPath.row].image
        return cell
    }
}

extension PhotoBookViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePhotoBookParallax()
    }
}
