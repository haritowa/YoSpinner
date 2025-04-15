import UIKit
import ObjectiveC

// MARK: - UIView Extension

extension UIView {
    private struct AssociatedKeys {
        static var spinnerBarView = "spinnerBarViewKey"
    }
    
    /// The spinner bar view currently attached to this view, if any.
    private var spinnerBarView: SFSpinnerBar? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.spinnerBarView) as? SFSpinnerBar
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.spinnerBarView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Starts a spinner animation on top of this view.
    /// - Parameters:
    ///   - model: The spinner model to use, or nil to use a default model.
    ///   - insets: Optional insets to apply to the spinner container.
    ///   - contentInsets: Insets applied to the content inside the spinner (affects icon size and spacing).
    ///   - adaptToContainer: Whether the spinner should adapt icon size to fit the container.
    ///   - iconSize: Preferred icon size when not adapting to container.
    ///   - cornerRadius: Optional corner radius for the blur background (nil = use view's corner radius)
    ///   - completion: Closure called when the spinner animation has started.
    /// - Returns: The spinner bar view that was created.
    @discardableResult
    public func startSpinner(
        model: SFSpinnerModel,
        insets: UIEdgeInsets = .zero,
        contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
        adaptToContainer: Bool = true,
        iconSize: CGFloat = 48.0,
        cornerRadius: CGFloat? = nil,
        completion: (() -> Void)? = nil
    ) -> SFSpinnerBar {
        // If there's already a spinner, end it first to avoid overlapping spinners
        if let existingSpinner = spinnerBarView {
            // If it's already a spinner with the same configuration, just begin it
            if let existingSpinnerView = existingSpinner as? SFSpinnerBarView,
               existingSpinnerView.spinnerModel.numberOfSymbols == model.numberOfSymbols {
                existingSpinner.begin(completion: completion)
                return existingSpinner
            } else {
                // Otherwise, end the existing spinner before creating a new one
                endSpinner()
            }
        }
        
        // Create spinner view with configuration
        let spinner = SFSpinnerBarView(
            model: model, 
            contentInsets: contentInsets,
            adaptToContainer: adaptToContainer,
            preferredIconSize: iconSize
        )
        
        // Ensure spinner is configured correctly
        guard let spinnerView = spinner as? UIView else {
            fatalError("Spinner must be a UIView")
        }
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate the actual corner radius to use
        let effectiveCornerRadius = cornerRadius ?? self.layer.cornerRadius
        
        // Configure the spinner's blur view corner radius if needed
        if let blurView = spinnerView.subviews.first as? UIVisualEffectView, effectiveCornerRadius > 0 {
            blurView.layer.cornerRadius = effectiveCornerRadius
        }
        
        // Add to view hierarchy
        addSubview(spinnerView)
        
        // Setup constraints with insets
        NSLayoutConstraint.activate([
            spinnerView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            spinnerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            spinnerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            spinnerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
        
        // Store reference
        spinnerBarView = spinner
        
        // Start animation
        spinner.begin(completion: completion)
        
        return spinner
    }
    
    /// Ends the spinner animation and removes it from this view.
    /// - Parameter completion: Closure called when the spinner has been removed.
    public func endSpinner(completion: (() -> Void)? = nil) {
        guard let spinner = spinnerBarView else {
            completion?()
            return
        }
        
        // End animation and remove spinner
        spinner.end { [weak self] in
            // Remove from view hierarchy
            if let spinnerView = spinner as? UIView {
                spinnerView.removeFromSuperview()
            }
            
            // Clear reference
            self?.spinnerBarView = nil
            
            // Call completion
            completion?()
        }
    }
} 