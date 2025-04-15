import UIKit

/// Defines the interface for controlling an SF Symbol spinner bar.
public protocol SFSpinnerBar: UIView {
    /// Begins the spinner animation, causing symbols to appear with animation.
    /// - Parameter completion: An optional closure called when the animation finishes.
    func begin(completion: (() -> Void)?)

    /// Ends the spinner animation, causing symbols to disappear with animation.
    /// - Parameter completion: An optional closure called when the animation finishes.
    func end(completion: (() -> Void)?)
    
    /// The model containing spinner configuration.
    var spinnerModel: SFSpinnerModel { get }
} 