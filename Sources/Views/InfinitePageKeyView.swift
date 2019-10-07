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

let randomColors = [
    UIColor.red,
    UIColor.gray,
    UIColor.green,
    UIColor.blue,
    UIColor.purple,
    UIColor.yellow,
    UIColor.magenta,
    UIColor.brown
]

final class CircleView: UIView {

    /// The circle's scale transform.
    var scaleTransform: CGAffineTransform = .identity {
        didSet { updateTransform() }
    }

    /// The circle's translation transform.
    var translationTransform: CGAffineTransform = .identity {
        didSet { updateTransform() }
    }

    private func updateTransform() {
        transform = scaleTransform.concatenating(translationTransform)
    }
}

//------------------------------------------------------------------------------------------------------------
//  Infinite animation. Each line below shows a state change that occurs as the user scrolls.
//     (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)   - all elements (numberOfPages: 10)
//     [0, 1, 2, 3, 4]...               - visible elements (numberOfCircles: 5)
//      ^                               - cursor position
//         ^
//            ^
//    .[1, 2, 3, 4, 5]...
//   ..[2, 3, 4, 5, 6]...
//  ...[3, 4, 5, 6, 7]..
//  ...[4, 5, 6, 7, 8].
//  ...[5, 6, 7, 8, 9]
//               ^
//                  ^
//------------------------------------------------------------------------------------------------------------
//  Travel ratio: at the edges of the list
//     (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)   - all elements
//     {0, 1, 2}            {7, 8, 9}   - edge elements where cursor position changes.
//------------------------------------------------------------------------------------------------------------
// Wrapping behavior:
//     ...|0 1 2 3 4|...            - visible indices (numberOfCircles: 5)
//       ...|1 2 3 4 0|...
//         ...|2 3 4 0 1|...
//           ...|3 4 0 1 2|...
//             ...|4 0 1 2 3|...
//               ...|0 1 2 3 4|...
//
//  TravelWidth = numberOfCircles * CircleWidth
//  NumWraps(i) = (Travel / circleWidth) * (numberOfCircles - i)
//  MidX(i) = (Travel * circleWidth) % numberOfCircles
final class InfinitePageKeyView: UIView {
    
    /// Set the number of pages this key view is capable of representing.
    @IBInspectable var numberOfPages: Int = 3 {
        didSet { buildUI() }
    }

    var numberOfCircles: Int = 7 {
        didSet { buildUI() }
    }

    var stepDistance: CGFloat {
        return floor(bounds.width / CGFloat(numberOfCircles))
    }

    /// Distance the container has traveled.
    var travel: CGFloat = 0 {
        didSet {
            let translation3d = CATransform3DMakeTranslation(-travel, 0, 0)
            travelView?.layer.transform = translation3d
        }
    }

    var numberOfTravelSteps: Int {
        return max(numberOfPages - numberOfCircles, 0)
    }

    var travelRatio: Double {
        return 1 / floor(Double(numberOfCircles) / 2)
    }

    /// The center cursor location.
    var centerPosition: CGFloat {
        return leftPosition + (floor(CGFloat(numberOfCircles) / 2) * stepDistance)
    }
    
    /// The left-most cursor position.
    var leftPosition: CGFloat {
        return circleContainerView?.bounds.minX ?? 0
    }
    
    /// The right-most cursor position.
    var rightPosition: CGFloat {
        return leftPosition + ceil(CGFloat(numberOfCircles - 1) * stepDistance)
    }

    /// The current cursor position.
    var cursorPosition: CGFloat = 0.0 {
        didSet { updateCursor() }
    }
    
    /// The current cursor size.
    var cursorScale: CGFloat = 1 {
        didSet { updateCursor() }
    }

    func updateCursor() {
        let scale = CGAffineTransform(scaleX: cursorScale, y: cursorScale)
        let translation = CGAffineTransform(translationX: cursorPosition, y: 0)
        cursorView?.transform = scale.concatenating(translation)
    }

    /// All circle views, excluding the cursor.
    private(set) var circleViews: [CircleView] = []

    private weak var cursorView: UIView?
    private weak var travelView: UIView?
    private weak var circleContainerView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        buildUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let viewCenter = bounds.center

        travelView?.bounds = bounds
        travelView?.center = viewCenter

        circleContainerView?.bounds = bounds
        circleContainerView?.center = viewCenter
        
        let circleDiameter = stepDistance
        let circleRadius = floor(circleDiameter / 2)

        let circleSize = CGSize(width: circleDiameter, height: circleDiameter)
        let circleCenter = CGPoint(x: circleRadius, y: viewCenter.y)
        circleContainerView?.subviews.enumerated().forEach { i, circleView in
            circleView.bounds.size = circleSize
            circleView.center = circleCenter
            circleView.bounds = circleView.bounds.integral
            circleView.layer.cornerRadius = circleRadius
        }
        
        cursorView?.bounds.size = circleSize
        cursorView?.center = circleCenter
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

        circleViews = (0 ..< numberOfCircles).map { _ in
            let circleView = createCircleView(isHollow: true)
            circleContainerView.addSubview(circleView)
//            circleView.backgroundColor = randomColors.randomElement()
            return circleView
        }

        let cursorView = createCircleView(isHollow: false)
        addSubview(cursorView)

        self.travelView = travelView
        self.circleContainerView = circleContainerView
        self.cursorView = cursorView

        setNeedsLayout()
        layoutIfNeeded()

//        self.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
//        travelView.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
    }
    
    private func createCircleView(isHollow: Bool) -> CircleView {
        let view = CircleView()
        view.backgroundColor = isHollow ? UIColor.init(white: 1, alpha: 0.5) : UIColor.white
        return view
    }
}
