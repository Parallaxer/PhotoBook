import Parallaxer
import UIKit
import RxSwift
import RxCocoa

private let kPhotoBookCellID = "PhotoBookCell"

final class PhotoBookViewController: UIViewController {
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var infinitePageKeyView: InfinitePageKeyView!
    @IBOutlet fileprivate var pageKeyView: PageKeyView!
    @IBOutlet fileprivate var photoInfoView: PhotoInfoView!
    @IBOutlet fileprivate var photoInfoHeightConstraint: NSLayoutConstraint!
    
    var photoInfoInteraction: ClosureBasedScrollView?
    
    fileprivate let photos = PhotoInfo.defaultPhotos

    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        infinitePageKeyView.numberOfPages = photos.count
        pageKeyView.numberOfPages = photos.count
        collectionView.reloadData()

        preparePhotoInfoInteraction()

        bindObservables()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePhotoInfoParallax()
        updatePhotoBookParallax()
    }

    private func bindObservables() {
        let viewController = Observable.just(self)
        let pageChange = collectionView.rx.contentOffset
            .map { $0.x }

        let together = Observable.combineLatest(viewController, pageChange)
            .flatMap { (arg) -> Observable<ParallaxProgress<CGFloat>> in
                let (viewController, pageChange) = arg
                let interval = viewController.pageChangeInterval
                return Observable.just(pageChange)
                    .asParallaxObservable(over: interval)
            }


        infinitePageKeyView.connect(pageChangeProgress: together)
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
