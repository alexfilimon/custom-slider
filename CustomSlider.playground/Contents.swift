import UIKit
import PlaygroundSupport

let slider = CustomSlider(frame: CGRect(origin: .zero, size: CGSize(width: 600, height: 120)))
slider.backgroundColor = .white
slider.setValue(50)

PlaygroundPage.current.liveView = slider
