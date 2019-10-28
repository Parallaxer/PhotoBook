import Parallaxer
import UIKit
import RxSwift
import RxCocoa

private let kPhotoBookCellID = "PhotoBookCell"

final class PhotoBookViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var infinitePageKeyView: InfinitePageKeyView!
    @IBOutlet fileprivate var infinitePageView: InfinitePageView!
    @IBOutlet fileprivate var pageKeyView: PageKeyView!
    @IBOutlet fileprivate var photoInfoView: PhotoInfoView!
    @IBOutlet fileprivate var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteraction: UIScrollView?
    
    fileprivate let photos = PhotoInfo.defaultPhotos

    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        infinitePageView.numberOfPages = photos.count
        infinitePageKeyView.numberOfPages = photos.count
        pageKeyView.numberOfPages = photos.count
        collectionView.reloadData()

        preparePhotoInfoInteraction()

        bindObservables()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func bindObservables() {
        let scrollingTransform = photoBookScrollingTransform
            .share(replay: 1)
        
        visiblePhotoIndex
            .drive(onNext: { [unowned self] index in
                self.photoInfoView.populate(withPhotoInfo: self.photos[index])
            })
            .disposed(by: disposeBag)

        bindPhotoInfoParallax()
            .disposed(by: disposeBag)

        pageKeyView.bindPageKeyParallax(with: scrollingTransform)
            .disposed(by: disposeBag)

        infinitePageKeyView.bindPageKeyParallax(with: scrollingTransform)
            .disposed(by: disposeBag)

        infinitePageView.bindScrollingTransform(scrollingTransform)
            .disposed(by: disposeBag)
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
