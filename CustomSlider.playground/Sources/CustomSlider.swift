import UIKit

final public class CustomSlider: UIControl {

    // MARK: - Nested types

    public enum Constants {
        // track
        static let trackHeight: CGFloat = 20
        static let trackTopOffset: CGFloat = 40
        static let trackHorizontalOffset: CGFloat = 40

        // labels
        static let labelFontSize: CGFloat = 20
        static let labelFont: UIFont = UIFont.systemFont(ofSize: 20)
        static let labelFromTrackTopOffset: CGFloat = 50

        // points
        static let smallPointSize: CGFloat = 20
        static let bigPointSize: CGFloat = 24
        static let smallPointOpacity: Float = 0.1

        // thumb
        static let thumbSize = CGSize(width: 70, height: 81)
        static let thumbImageDyOffset: CGFloat = 11
    }

    // MARK: - Readonly properties

    private(set) var values: [Int] = []
    private(set) lazy var value: Int = minValue

    // MARK: - Properties

    private var minValue: Int {
        return values.first ?? 0
    }
    private var maxValue: Int {
        return values.last ?? 100
    }
    private var points: [Int: (bigPoint: CAShapeLayer, smallPoint: CAShapeLayer)] = [:]
    private var labels: [Int: CATextLayer] = [:]
    private var thumbImage = UIImage(named: "Group 6.png")
    private var trackLayer = CustomSliderTrackLayer()
    private let thumbImageView = UIImageView()
    private var canSlide = false

    // MARK: - Initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureAppearance()
    }

    // MARK: - UIControl

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return handleBeginTracking(with: touch.location(in: self))
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return handleContinueTracking(with: touch.location(in: self))
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        handleEndTracking(with: touch?.location(in: self))
    }

    // MARK: - UIView

    override public func layoutSubviews() {
        super.layoutSubviews()

        updateLayerFrames()
    }

    // MARK: - Public methods

    public func setValue(_ value: Int) {
        self.value = boundValue(value)
        animateChanging()
    }

    public func configure(with values: [Int]) {
        self.values = values
        self.value = minValue
        configurePoints()
        configureLabels()
        thumbImageView.frame = updatedThumbFrame()
    }

    // MARK: - Private methods

    private func configureAppearance() {
        trackLayer.contentsScale = UIScreen.main.scale
        trackLayer.cornerRadius = Constants.trackHeight / 2
        trackLayer.percentage = percentage(for: value)
        layer.addSublayer(trackLayer)

        configurePoints()
        configureLabels()

        thumbImageView.image = thumbImage
        thumbImageView.contentMode = .center
        addSubview(thumbImageView)

        updateLayerFrames()
    }

    private func updateLayerFrames() {
        // track
        let trackSize = CGSize(
            width: bounds.size.width - Constants.trackHorizontalOffset * 2,
            height: Constants.trackHeight
        )
        trackLayer.frame = CGRect(origin: trackOrigin(), size: trackSize)
        trackLayer.setNeedsDisplay()

        // thumb image
        thumbImageView.frame = updatedThumbFrame()

        // points
        drawPoints()

        // labels
        drawLabels()
    }

    func percentage(for value: Int) -> CGFloat {
        return CGFloat(value - minValue) / CGFloat(maxValue - minValue)
    }

    private func animateChanging() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(GlobalConstants.animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))

        // animate track
        trackLayer.percentage = percentage(for: value)

        // animate thumb frame
        let frameAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        let oldFrame = thumbImageView.layer.presentation()?.frame ?? .zero
        let newFrame = updatedThumbFrame()
        frameAnimation.fromValue = CGPoint(x: oldFrame.midX, y: oldFrame.midY)
        frameAnimation.toValue = CGPoint(x: newFrame.midX, y: newFrame.midY)
        thumbImageView.layer.removeAllAnimations()
        thumbImageView.layer.add(frameAnimation, forKey: #keyPath(CALayer.position))
        thumbImageView.frame = newFrame

        CATransaction.commit()
    }

    private func trackOrigin() -> CGPoint {
        let y = Constants.trackTopOffset
        return CGPoint(x: bounds.minX + Constants.trackHorizontalOffset, y: y)
    }

    private func handleBeginTracking(with location: CGPoint) -> Bool {
        // to understand if was touch or pan on endTracking
        canSlide = thumbImageView.frame.contains(location)

        return true
    }

    private func handleContinueTracking(with location: CGPoint) -> Bool {
        guard canSlide else {
            return false
        }

        let trackContentHorizontalOffset = Constants.trackHeight / 2 + Constants.trackHorizontalOffset
        let trackContentWidth = bounds.width - trackContentHorizontalOffset * 2
        let percentage = (location.x - trackContentHorizontalOffset) / trackContentWidth
        var newValue = Int(percentage * CGFloat(maxValue - minValue)) + minValue
        newValue = boundValue(newValue)
        newValue = nearestValue(for: newValue)

        if newValue != value {
            value = newValue
            animateChanging()
            sendActions(for: .valueChanged)
        }

        return true
    }

    private func handleEndTracking(with location: CGPoint?) {
        guard !canSlide, let x = location?.x else {
            return
        }

        let trackContentHorizontalOffset = Constants.trackHeight / 2 + Constants.trackHorizontalOffset
        let trackContentWidth = bounds.width - trackContentHorizontalOffset * 2
        let newPercentage = (x - trackContentHorizontalOffset) / trackContentWidth

        var newValue = Int(newPercentage * CGFloat(maxValue - minValue)) + minValue
        newValue = boundValue(newValue)
        newValue = nearestValue(for: newValue)

        if newValue != value {
            value = newValue
            animateChanging()
            sendActions(for: .valueChanged)
        }
    }

    private func boundValue(_ value: Int) -> Int {
        return min(max(value, minValue), maxValue)
    }

    private func configurePoints() {
        removeOldPoints()

        for value in values {
            guard value != minValue && value != maxValue else {
                continue
            }
            let smallPoint = CAShapeLayer()
            let bigPoint = CAShapeLayer()
            points[value] = (bigPoint: bigPoint, smallPoint: smallPoint)
            layer.addSublayer(bigPoint)
            layer.addSublayer(smallPoint)
        }

        bringSubviewToFront(thumbImageView)
    }

    private func configureLabels() {
        removeOldLabels()

        for value in values {
            let label = CATextLayer()
            label.font = Constants.labelFont
            label.fontSize = Constants.labelFontSize
            label.foregroundColor = GlobalConstants.grayTextColor.cgColor
            label.string = String(Int(value))
            label.contentsScale = UIScreen.main.scale

            // alignment
            if value == minValue {
                label.alignmentMode = .left
            } else if value == maxValue {
                label.alignmentMode = .right
            } else {
                label.alignmentMode = .center
            }

            labels[value] = label
            layer.addSublayer(label)
        }
    }

    private func smallPointOrigin(for value: Int) -> CGPoint {
        let x = position(for: value) - Constants.smallPointSize / 2
        let y = Constants.trackTopOffset + (Constants.trackHeight - Constants.smallPointSize) / 2
        return CGPoint(x: x, y: y)
    }

    private func bigPointOrigin(for value: Int) -> CGPoint {
        let x = position(for: value) - Constants.bigPointSize / 2
        let y = Constants.trackTopOffset + (Constants.trackHeight - Constants.bigPointSize) / 2
        return CGPoint(x: x, y: y)
    }

    private func drawPoints() {
        for point in points {
            let smallPointSize = CGSize(width: Constants.smallPointSize, height: Constants.smallPointSize)
            let bigPointSize = CGSize(width: Constants.bigPointSize, height: Constants.bigPointSize)
            let smallOvalPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: smallPointSize))
            let bigOvalPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: bigPointSize))

            point.value.smallPoint.frame = CGRect(origin: smallPointOrigin(for: point.key), size: smallPointSize)
            point.value.bigPoint.frame = CGRect(origin: bigPointOrigin(for: point.key), size: bigPointSize)

            point.value.smallPoint.path = smallOvalPath.cgPath
            point.value.bigPoint.path = bigOvalPath.cgPath

            point.value.bigPoint.lineWidth = Constants.bigPointSize - Constants.smallPointSize
            point.value.bigPoint.fillColor = UIColor.clear.cgColor
            point.value.bigPoint.strokeColor = backgroundColor?.cgColor

            point.value.smallPoint.fillColor = UIColor.black.cgColor
            point.value.smallPoint.opacity = Constants.smallPointOpacity

            point.value.smallPoint.setNeedsDisplay()
            point.value.bigPoint.setNeedsDisplay()
        }
    }

    private func position(for value: Int) -> CGFloat {
        let trackContentHorizontalOffset = Constants.trackHeight / 2 + Constants.trackHorizontalOffset
        let trackContentWidth = bounds.width - trackContentHorizontalOffset * 2
        let contentHOffset = trackContentHorizontalOffset
        return percentage(for: value) * trackContentWidth + contentHOffset
    }

    private func drawLabels() {
        for label in labels {
            let x = position(for: label.key)
            let labelSize = CGSize(width: trackLayer.bounds.width, height: Constants.labelFontSize)
            label.value.bounds = CGRect(origin: .zero, size: labelSize)

            let trackTopOffset = Constants.trackTopOffset
            let trackHeight = Constants.trackHeight
            let labelTopOffset = Constants.labelFromTrackTopOffset
            let y = trackTopOffset + trackHeight + labelTopOffset

            if label.key == minValue || label.key == maxValue {
                label.value.position = CGPoint(x: trackLayer.position.x, y: y)
            } else {
                label.value.position = CGPoint(x: x, y: y)
            }
        }
    }

    private func removeOldPoints() {
        for point in points {
            point.value.smallPoint.removeFromSuperlayer()
            point.value.bigPoint.removeFromSuperlayer()
        }
        points.removeAll()
    }

    private func removeOldLabels() {
        for label in labels {
            label.value.removeFromSuperlayer()
        }
        labels.removeAll()
    }

    private func nearestValue(for value: Int) -> Int {
        let diffs = values.map {
            abs($0 - value)
        }
        let minIndex = diffs.firstIndex(of: diffs.min() ?? minValue) ?? 0
        return values[minIndex]
    }

    private func thumbOrigin(for value: Int) -> CGPoint {
        let x = position(for: value) - Constants.thumbSize.width / 2
        let thumbHeight = Constants.thumbSize.height
        let trackHeight = Constants.trackHeight
        let thumbImageDyOffset = Constants.thumbImageDyOffset
        let y = Constants.trackTopOffset - (thumbHeight + trackHeight) / 2 + thumbImageDyOffset
        return CGPoint(x: x, y: y)
    }

    private func updatedThumbFrame() -> CGRect {
        let thumbFrame = CGRect(origin: thumbOrigin(for: value), size: Constants.thumbSize)
        return thumbFrame.offsetBy(dx: 0, dy: Constants.thumbImageDyOffset)
    }

}

