import UIKit

extension Int {

    var isEven: Bool {
        return self % 2 == 0
    }
}

extension CGRect {

    /// The rect's center point.
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
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

    var numberOfCircles: Int = 7 {
        didSet {
            if numberOfCircles.isEven {
                fatalError(
                    """
                    For the sake of visual symmetry, numberOfVisiblePages must be an odd number. Received
                    \(numberOfCircles).
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

    var stepDistance: CGFloat {
        return round(bounds.width / CGFloat(numberOfCircles))
    }

    /// Distance the container has traveled.
    var travel: CGFloat = 0 {
        didSet {
            let translation3d = CATransform3DMakeTranslation(-travel, 0, 0)
            travelView?.layer.transform = translation3d
        }
    }

    var travelRatio: Double {
        guard let count = circleContainerView?.subviews.count, count > 0 else {
            return 1
        }

        let ratio = (floor(Double(count) / 2) / Double(numberOfPages - 1))
        guard ratio < 0.5 else {
            return 1
        }

        return ratio
    }

    /// The center cursor location.
    var centerPosition: CGFloat {
        return circleContainerView?.bounds.midX ?? 0
    }
    
    /// The left-most cursor position.
    var leftPosition: CGFloat {
        guard let bounds = circleContainerView?.bounds else {
            return 0
        }
        return bounds.minX + (stepDistance / 2)
    }
    
    /// The right-most cursor position.
    var rightPosition: CGFloat {
        guard let bounds = circleContainerView?.bounds else {
            return 0
        }
        return bounds.maxX - (stepDistance / 2)
    }

    /// The current cursor position.
    var cursorPosition: CGFloat {
        get { return cursorView?.center.x ?? 0 }
        set { cursorView?.center.x = newValue }
    }
    
    /// The current cursor size.
    var cursorScale: CGFloat {
        get { return cursorView?.transform.a ?? 0 }
        set { cursorView?.transform = CGAffineTransform(scaleX: newValue, y: newValue) }
    }

    /// All circle views, excluding the cursor.
    var circleViews: [UIView] {
        return circleContainerView?.subviews ?? []
    }

    private weak var cursorView: UIView?
    private weak var travelView: UIView?
    private weak var circleContainerView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        travelView?.bounds = bounds
        travelView?.center = CGPoint(x: bounds.midX, y: bounds.midY)

        circleContainerView?.bounds = bounds
        circleContainerView?.center = bounds.center
        
        let cellWidth = round(bounds.width / CGFloat(numberOfCircles))
        let circleDiameter = min(cellWidth, bounds.height)
        let circleRadius = round(circleDiameter / 2)
        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)
        let centerY = round(bounds.height / 2)
        circleContainerView?.subviews.enumerated().forEach { i, circleView in
            circleView.bounds.size = circleSize
            circleView.bounds = circleView.bounds.integral
            let centerX = cellWidth * CGFloat(i + 1) - round(cellWidth / 2)
            circleView.center = CGPoint(x: centerX, y: centerY)
            circleView.layer.cornerRadius = circleRadius
        }
        
        cursorView?.bounds.size = circleSize
        cursorView?.center.y = centerY
        cursorView?.layer.cornerRadius = circleRadius
    }

    /// Calculate the squared distance between the specified subview and the cursor. This is the squared
    /// distance, which is useful for (performant) relative distance comparisons.
    ///
    /// - Parameter subview: A subview of the page key view.
    /// - Returns: The quared distance between the specified subview and the cursor.
    func distanceSquaredFromCursor(for subview: UIView) -> CGFloat {
        guard let cursorView = self.cursorView else {
            return 0
        }

        let cursorBoundsRelativeToView = cursorView.convert(cursorView.bounds, to: self)
        let subviewBoundsRelativeToView = subview.convert(subview.bounds, to: self)

        let cursorCenter = CGPoint(x: cursorBoundsRelativeToView.midX, y: cursorBoundsRelativeToView.midY)
        let subviewCenter = CGPoint(x: subviewBoundsRelativeToView.midX, y: subviewBoundsRelativeToView.midY)

        // Distance formula, without the square-root, performant way to compare relative distances.
        return pow(cursorCenter.x - subviewCenter.x, 2) + pow(cursorCenter.y - subviewCenter.y, 2)
    }
    
    private func buildUI() {
        self.cursorView?.removeFromSuperview()
        self.travelView?.removeFromSuperview()
        
        let travelView = UIView()
        addSubview(travelView)

        let circleContainerView = UIView()
        travelView.addSubview(circleContainerView)

        for _ in 0 ..< numberOfCircles {
            let circleView = createCircleView(true)
            circleContainerView.addSubview(circleView)
        }
        
        let cursorView = createCircleView(false)
        addSubview(cursorView)

        self.travelView = travelView
        self.circleContainerView = circleContainerView
        self.cursorView = cursorView

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func createCircleView(_ isHollow: Bool) -> UIView {
        let view = UIView()
        view.backgroundColor = isHollow ? UIColor.init(white: 1, alpha: 0.5) : UIColor.white
        return view
    }
}
