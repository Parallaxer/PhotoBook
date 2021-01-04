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
    
    private lazy var photoBookAnimation: PhotoBookAnimation = {
        return PhotoBookAnimation(
            photoBookLayout: collectionView.collectionViewLayout as! PhotoBookCollectionViewLayout,
            photoBookCollectionView: collectionView)
    }()
    
    private lazy var verticalInteractionView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame.size.height = view.bounds.height
        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        scrollView.isPagingEnabled = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
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

        setUpPhotoBookInteraction()
        setUpPhotoInfoInteraction()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension PhotoBookViewController {
    
    private func setUpPhotoBookInteraction () {
        photoBookAnimation
            .visiblePhotoIndex
            .drive(onNext: { [weak self] index in
                guard let self = self else {
                    return
                }
                self.photoInfoView.populate(withPhotoInfo: self.photos[index])
            })
            .disposed(by: disposeBag)

        infinitePageView
            .bindScrollingTransform(photoBookAnimation.photoBookScrollingTransform)
            .disposed(by: disposeBag)
    }
    
    private func setUpPhotoInfoInteraction() {
        view.addGestureRecognizer(verticalInteractionView.panGestureRecognizer)
        view.addSubview(verticalInteractionView)
        
        let interactionTransform = verticalInteractionView.rx.contentOffset
            .map { return $0.y }
            // Create a transform which follows the content offset over the interval of interaction.
            .parallax(over: .interval(from: 0, to: verticalInteractionView.bounds.height))
        
        let photoInfoAnimation = PhotoInfoAnimation(maxDrawerLength: 128)
        
        photoInfoAnimation
            .photoBookInteractionEnabled
            .asObservable()
            .bind(to: collectionView.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
        
        photoInfoAnimation
            .photoBookAlpha
            .asObservable()
            .bind(to: collectionView.rx.alpha)
            .disposed(by: disposeBag)
        
        photoInfoAnimation
            .photoBookScale
            .emit(onNext: { [weak self] scale in
                self?.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            })
            .disposed(by: disposeBag)
        
        photoInfoAnimation
            .photoInfoDrawerLength
            .asObservable()
            .bind(to: photoInfoHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        photoInfoAnimation
            .bindDrawerInteraction(interactionTransform)
            .disposed(by: disposeBag)
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

        photoBookAnimation
            .bindPagingParallax(to: cell, at: indexPath)
            .disposed(by: cell.disposeBag)

        return cell
    }
}
