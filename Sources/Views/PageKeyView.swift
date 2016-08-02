import UIKit

class PageKeyView: UIView {
    
    /// Set the number of pages this key view is capable of representing.
    @IBInspectable var numberOfPages: Int = 3 {
        didSet { self.buildUI() }
    }
    
    /// The left-most slider position.
    var leftPosition: CGFloat {
        return self.outlineContainerView?.subviews.first?.center.x ?? 0
    }
    
    /// The right-most slider position.
    var rightPosition: CGFloat {
        return self.outlineContainerView?.subviews.last?.center.x ?? 0
    }
    
    /// The current slider position.
    var sliderPosition: CGFloat {
        get { return self.sliderView?.center.x ?? 0 }
        set { self.sliderView?.center.x = newValue }
    }
    
    /// The current slider size.
    var sliderScale: CGFloat {
        get { return self.sliderView?.transform.a ?? 0 }
        set { self.sliderView?.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }
    
    /// Rotation, in radians, of the entire view around the y-axis.
    var rotation: CGFloat = 0 {
        didSet {
            var perspectiveMatrix = CATransform3DIdentity
            perspectiveMatrix.m34 = -1.0 / 200
            let rotation3D = CATransform3DRotate(perspectiveMatrix, self.rotation, 0, 1, 0)
            self.containerView?.layer.transform = rotation3D
        }
    }
    
    private weak var containerView: UIView?
    private weak var outlineContainerView: UIView?
    private weak var sliderView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.buildUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.containerView?.frame = self.bounds
        self.outlineContainerView?.frame = self.bounds
        
        let cellWidth = round(self.bounds.width / CGFloat(self.numberOfPages))
        let circleDiameter = min(cellWidth, self.bounds.height)
        let circleRadius = round(circleDiameter / 2)
        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)
        let centerY = round(self.bounds.height / 2)
        self.outlineContainerView?.subviews.enumerated().forEach { i, outlineView in
            outlineView.frame.size = circleSize
            outlineView.frame = outlineView.frame.integral
            let centerX = cellWidth * CGFloat(i + 1) - round(cellWidth / 2)
            outlineView.center = CGPoint(x: centerX, y: centerY)
            outlineView.layer.cornerRadius = circleRadius
        }
        
        self.sliderView?.bounds.size = circleSize
        self.sliderView?.center.y = centerY
        self.sliderView?.layer.cornerRadius = circleRadius
    }
    
    private func buildUI() {
        self.containerView?.removeFromSuperview()
        
        let containerView = UIView()
        self.addSubview(containerView)
        self.containerView = containerView
        
        let outlineContainerView = UIView()
        self.containerView?.addSubview(outlineContainerView)
        self.outlineContainerView = outlineContainerView
        
        for _ in 0 ..< self.numberOfPages {
            let outlineView = self.createCircleView(isHollow: true)
            self.outlineContainerView?.addSubview(outlineView)
        }
        
        let sliderView = self.createCircleView(isHollow: false)
        self.containerView?.addSubview(sliderView)
        self.sliderView = sliderView
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func createCircleView(isHollow: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = isHollow ? UIColor.init(white: 1, alpha: 0.5) : UIColor.white()
        return view
    }
}
