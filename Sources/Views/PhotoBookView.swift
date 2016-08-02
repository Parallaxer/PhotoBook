import Parallaxer
import UIKit

protocol PhotoBookViewDelegate: class {
    
    func photoBook(_ photoBookView: PhotoBookView, willSeedParallaxTree parallaxTree: inout ParallaxEffect<CGFloat>)
    func photoBook(_ photoBookView: PhotoBookView, didSelectPageAtIndex index: Int)
}

class PhotoBookView: UIView {

    weak var delegate: PhotoBookViewDelegate?
    
    /// The images in the photo book.
    var images: [UIImage] {
        get { return self.pageViews.flatMap { $0.image } }
        set { self.preparePages(withImages: newValue) }
    }

    private var currentPage: Int? {
        didSet {
            if let currentPage = self.currentPage, currentPage != oldValue {
                self.delegate?.photoBook(self, didSelectPageAtIndex: currentPage)
            }
        }
    }
    
    private let scrollView = UIScrollView()
    private var pageViews: [PageView] {
        return self.scrollView.subviews.flatMap({ $0 as? PageView })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.scrollView.delegate = self
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.isPagingEnabled = true
        self.addSubview(self.scrollView)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let pages = self.pageViews
        let lastPageRect = self.rectForPage(number: pages.count - 1)
        self.scrollView.frame = self.bounds
        self.scrollView.contentSize =  CGSize(width: lastPageRect.maxX, height: lastPageRect.maxY)
        for (pageNumber, page) in self.pageViews.enumerated() {
            page.frame = self.rectForPage(number: pageNumber)
        }
        
        self.seedParallaxTree()
    }
    
    private func rectForPage(number: Int) -> CGRect {
        let offset = self.bounds.width * CGFloat(number)
        return CGRect(origin: CGPoint(x: offset, y: 0), size: self.bounds.size)
    }
    
    private func preparePages(withImages images: [UIImage]) {
        self.currentPage = nil
        self.scrollView.subviews.forEach { $0.removeFromSuperview() }
        for image in images {
            let page = PageView()
            page.image = image
            self.scrollView.addSubview(page)
        }
    }
}

extension PhotoBookView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.seedParallaxTree()
    }
}

extension PhotoBookView {
    
    private func seedParallaxTree() {
        var controller = self.parallaxTree
        self.delegate?.photoBook(self, willSeedParallaxTree: &controller)
        controller.seed(withValue: scrollView.contentOffset.x)
    }
    
    private var parallaxTree: ParallaxEffect<CGFloat> {
        let pages = self.pageViews
        let lastPagePosition = self.rectForPage(number: pages.count - 1).origin.x
        var scrollEffect = ParallaxEffect<CGFloat>(
            interval: ParallaxInterval(from: 0, to: lastPagePosition)
        )
        scrollEffect.addEffect(self.changePageNumberEffect)
        
        let unitPageWidth = 1 / Double(pages.count - 1)
        for (pageNumber, page) in pages.enumerated() {
            let pageStart = unitPageWidth * Double(pageNumber)
            let pageEnd = pageStart + unitPageWidth
            let subinterval = ParallaxInterval(from: pageStart, to: pageEnd)
            scrollEffect.addEffect(page.turnPageEffect, subinterval: subinterval)
        }
        
        return scrollEffect
    }
    
    private var changePageNumberEffect: ParallaxEffect<CGFloat> {
        return ParallaxEffect(
            interval: ParallaxInterval(from: 0, to: CGFloat(self.images.count - 1)),
            isClamped: true,
            onChange: { self.currentPage = Int(round($0)) }
        )
    }
}
