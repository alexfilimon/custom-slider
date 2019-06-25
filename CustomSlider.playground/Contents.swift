import UIKit
import PlaygroundSupport

let slider = CustomSlider(frame: CGRect(origin: .zero, size: CGSize(width: 600, height: 160)))
slider.backgroundColor = .white
slider.configure(with: [1, 10, 30, 40])

PlaygroundPage.current.liveView = slider
