import UIKit

class PageView: UIView {

    /// An image rendered on the page.
    var image: UIImage? {
        get { return self.imageView.image }
        set { self.imageView.image = newValue }
    }
    
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(self.imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
    }
}
