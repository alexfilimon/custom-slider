import UIKit

final public class CustomSliderTrackLayer: CALayer {

    // MARK: - Properties

    @NSManaged public var percentage: CGFloat

    // MARK: - Initialization

    // для обычной инициализации
    override init() {
        super.init()
    }

    // для инициализации при анимации
    override init(layer: Any) {
        super.init(layer: layer)
        guard let progressLayer = layer as? CustomSliderTrackLayer else {
            return
        }
        self.percentage = progressLayer.percentage
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - CALayer

    override public func draw(in context: CGContext) {
        // draw gray rect
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        context.addPath(path.cgPath)

        context.setFillColor(GlobalConstants.grayColor.cgColor)
        context.fillPath()

        // draw blue rect
        let trackHeight = CustomSlider.Constants.trackHeight
        let contentWidth = (bounds.width - trackHeight)
        let percentage = (presentation()?.percentage ?? 0)
        let valuePosition = percentage * contentWidth + trackHeight
        let rect = CGRect(x: 0, y: 0, width: valuePosition, height: bounds.height)
        let otherPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        context.addPath(otherPath.cgPath)

        context.setFillColor(GlobalConstants.blueColor.cgColor)
        context.fillPath()
    }

    override public class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(CustomSliderTrackLayer.percentage) {
            return true
        }
        return super.needsDisplay(forKey: key)

    }

    override public func action(forKey event: String) -> CAAction? {
        guard event == #keyPath(CustomSliderTrackLayer.percentage) else {
            return super.action(forKey: event)
        }

        let animation = CABasicAnimation(keyPath: event)
        animation.duration = GlobalConstants.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = presentation()?.value(forKey: event)
        return animation
    }

}
