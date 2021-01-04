import Parallaxer
import UIKit
import RxSwift
import RxCocoa

private let kPhotoBookCellID = "PhotoBookCell"

final class PhotoBookViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var infinitePageView: InfinitePageView!
    @IBOutlet fileprivate var photoInfoView: PhotoInfoView!
    @IBOutlet fileprivate var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteractionView: UIScrollView?
    
    fileprivate let photos = PhotoInfo.defaultPhotos

    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        infinitePageView.numberOfPages = photos.count
        collectionView.reloadData()
        
        // We need to make sure that the views have dimensionality so that our parallax intervals don't throw
        // an error. In a production app, you'll need to handle the cases where your view's size is zero, but
        // for the sake of this example, lets force the collection view to layout and show the content we just
        // loaded.
        collectionView.layoutIfNeeded()

        preparePhotoInfoInteraction()

        bindObservables()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func bindObservables() {
        visiblePhotoIndex
            .drive(onNext: { [unowned self] index in
                self.photoInfoView.populate(withPhotoInfo: self.photos[index])
            })
            .disposed(by: disposeBag)

        bindPhotoInfoParallax()
            .disposed(by: disposeBag)

        infinitePageView.bindScrollingTransform(photoBookScrollingTransform)
            .disposed(by: disposeBag)
    }
}

extension PhotoBookViewController: PhotoInfoAnimating {
    
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

extension PhotoBookViewController: PhotoBookAnimating {

    var photoBookCollectionView: UICollectionView {
        return collectionView
    }
    
    var photoBookLayout: PhotoBookCollectionViewLayout {
        return collectionView.collectionViewLayout as! PhotoBookCollectionViewLayout
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
            as! PhotoBookCollectionViewCell

        cell.image = photos[indexPath.row].image

        bindPagingParallax(to: cell, at: indexPath)
            .disposed(by: cell.disposeBag)

        return cell
    }
}
