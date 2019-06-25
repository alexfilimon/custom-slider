import UIKit

final public class CustomSlider: UIControl {

    // MARK: - Nested types

    public enum Constants {
        static let trackHeight: CGFloat = 20
        static let trackTopOffset: CGFloat = 40
        static let trackHorizontalOffset: CGFloat = 20
    }

    // MARK: - Properties

    private var minValue: Int = 10
    private var maxValue: Int = 1000
    private(set) lazy var value: Int = minValue

    private var trackLayer = CustomSliderTrackLayer()

    // MARK: - Initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureAppearance()
    }

    // MARK: - Public methods

    public func setValue(_ value: Int) {
        self.value = boundValue(value)
        animateChanging()
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

    // MARK: - Private methods

    private func configureAppearance() {
        trackLayer.contentsScale = UIScreen.main.scale
        trackLayer.cornerRadius = Constants.trackHeight / 2
        trackLayer.percentage = percentage(for: value)
        layer.addSublayer(trackLayer)
    }

    private func updateLayerFrames() {
        // track
        let trackSize = CGSize(
            width: bounds.size.width - Constants.trackHorizontalOffset * 2,
            height: Constants.trackHeight
        )
        trackLayer.frame = CGRect(origin: trackOrigin(), size: trackSize)
        trackLayer.setNeedsDisplay()
    }

    func percentage(for value: Int) -> CGFloat {
        return CGFloat(value - minValue) / CGFloat(maxValue - minValue)
    }

    private func animateChanging() {
        trackLayer.percentage = percentage(for: value)
    }

    private func trackOrigin() -> CGPoint {
        let y = Constants.trackTopOffset
        return CGPoint(x: bounds.minX + Constants.trackHorizontalOffset, y: y)
    }

    private func handleBeginTracking(with location: CGPoint) -> Bool {
        return true
    }

    private func handleContinueTracking(with location: CGPoint) -> Bool {

        let trackContentHorizontalOffset = Constants.trackHeight / 2 + Constants.trackHorizontalOffset
        let trackContentWidth = bounds.width - trackContentHorizontalOffset * 2
        let percentage = (location.x - trackContentHorizontalOffset) / trackContentWidth
        var newValue = Int(percentage * CGFloat(maxValue - minValue)) + minValue
        newValue = boundValue(newValue)

        if newValue != value {
            value = newValue
            animateChanging()
            sendActions(for: .valueChanged)
        }

        return true
    }

    private func handleEndTracking(with location: CGPoint?) {}

    private func boundValue(_ value: Int) -> Int {
        return min(max(value, minValue), maxValue)
    }

}

