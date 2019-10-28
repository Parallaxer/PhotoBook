import UIKit

final class PageKeyView: UIView {
    
    /// Set the number of pages this key view is capable of representing.
    @IBInspectable var numberOfPages: Int = 3 {
        didSet { buildUI() }
    }
    
    /// The left-most slider position.
    var leftPosition: CGFloat {
        return outlineContainerView?.subviews.first?.center.x ?? 0
    }
    
    /// The right-most slider position.
    var rightPosition: CGFloat {
        return outlineContainerView?.subviews.last?.center.x ?? 0
    }
    
    /// The current slider position.
    var sliderPosition: CGFloat {
        get { return sliderView?.center.x ?? 0 }
        set { sliderView?.center.x = newValue }
    }
    
    /// The current slider size.
    var sliderScale: CGFloat {
        get { return sliderView?.transform.a ?? 0 }
        set { sliderView?.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }
    
    /// Rotation, in radians, of the entire view around the y-axis.
    var rotation: CGFloat = 0 {
        didSet {
            var perspectiveMatrix = CATransform3DIdentity
            perspectiveMatrix.m34 = -1.0 / 200
            let rotation3D = CATransform3DRotate(perspectiveMatrix, rotation, 0, 1, 0)
            containerView?.layer.transform = rotation3D
        }
    }
    
    private weak var containerView: UIView?
    private weak var outlineContainerView: UIView?
    private weak var sliderView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView?.frame = bounds
        outlineContainerView?.frame = bounds

        let cellWidth = round(bounds.width / CGFloat(numberOfPages))
        let circleDiameter = min(cellWidth, bounds.height)
        let circleRadius = round(circleDiameter / 2)
        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)
        let centerY = round(bounds.height / 2)
        outlineContainerView?.subviews.enumerated().forEach { i, outlineView in
            outlineView.frame.size = circleSize
            outlineView.frame = outlineView.frame.integral
            let centerX = cellWidth * CGFloat(i + 1) - round(cellWidth / 2)
            outlineView.center = CGPoint(x: centerX, y: centerY)
            outlineView.layer.cornerRadius = circleRadius
        }
        
        sliderView?.bounds.size = circleSize
        sliderView?.center.y = centerY
        sliderView?.layer.cornerRadius = circleRadius
    }
    
    private func buildUI() {
        self.containerView?.removeFromSuperview()
        
        let containerView = UIView()
        addSubview(containerView)

        let outlineContainerView = UIView()
        containerView.addSubview(outlineContainerView)

        for _ in 0 ..< numberOfPages {
            let outlineView = createCircleView(true)
            outlineContainerView.addSubview(outlineView)
        }
        
        let sliderView = createCircleView(false)
        containerView.addSubview(sliderView)

        self.containerView = containerView
        self.outlineContainerView = outlineContainerView
        self.sliderView = sliderView

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func createCircleView(_ isHollow: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = isHollow ? UIColor.init(white: 1, alpha: 0.5) : UIColor.white
        return view
    }
}
