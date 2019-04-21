import UIKit

extension Int {

    var isEven: Bool {
        return self % 2 == 0
    }
}

//------------------------------------------------------------------------------------------------------------
//  Infinite animation. Each line below shows a state change that occurs as the user scrolls.
//     (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)   - all elements (numberOfPages: 10)
//     [0, 1, 2, 3, 4]...               - visible elements (numberOfVisiblePages: 5)
//      ^                               - cursor position
//         ^
//            ^
//     [0, 1, 2, 3, 4]...
//    .[1, 2, 3, 4, 5]...
//   ..[2, 3, 4, 5, 6]...
//  ...[3, 4, 5, 6, 7]..
//  ...[4, 5, 6, 7, 8].
//  ...[5, 6, 7, 8, 9]
//            ^
//               ^
//                  ^
//------------------------------------------------------------------------------------------------------------
//  Travel ratio: at the edges of the list
//     (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)   - all elements
//     {0, 1, 2}            {7, 8, 9}   - edge elements where cursor position changes.
final class InfinitePageKeyView: UIView {
    
    /// Set the number of pages this key view is capable of representing.
    @IBInspectable var numberOfPages: Int = 3 {
        didSet { buildUI() }
    }

    var numberOfVisiblePages: Int = 5 {
        didSet {
            if numberOfVisiblePages.isEven {
                fatalError(
                    """
                    For the sake of visual symmetry, numberOfVisiblePages must be an odd number. Received
                    \(numberOfVisiblePages).
                    """)
            }
            buildUI()
        }
    }

    var slidingWindowCount: Int = 3 {
        didSet {
            if slidingWindowCount.isEven {
                fatalError(
                    """
                    For the sake of visual symmetry, slidingWindowCount must be an odd number. Received
                    \(slidingWindowCount).
                    """)
            }
            buildUI()
        }
    }

    var travelRatio: Double {
        guard let count = outlineContainerView?.subviews.count, count > 0 else {
            return 1
        }

        let ratio = (floor(Double(count) / 2) / Double(numberOfPages - 1))
        guard ratio < 0.5 else {
            return 1
        }

        return ratio
    }

    /// The center slider location.
    var centerPosition: CGFloat {
        guard let count = outlineContainerView?.subviews.count, count > 0 else {
            return 0
        }
        let centerIndex = count / 2
        return outlineContainerView?.subviews[centerIndex].center.x ?? 0
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
        
        let cellWidth = round(bounds.width / CGFloat(numberOfVisiblePages))
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

        for _ in 0 ..< numberOfVisiblePages {
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
