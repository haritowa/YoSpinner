import UIKit
import SwiftUI
import ObjectiveC

// Component imports are handled by the Swift module system
// No need for explicit imports since they're all in the same module

// MARK: - View Implementation

/// A view that displays an animated spinner using SFSymbols, powered by UICollectionView.
final class SFSpinnerBarView: UIView, SFSpinnerBar, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Configuration
    private let model: SFSpinnerModel
    
    /// The spinner model containing configuration for the animation.
    var spinnerModel: SFSpinnerModel {
        return model
    }
    
    // Configuration options
    private var contentInsets: UIEdgeInsets = .zero
    private var adaptToContainer: Bool = true
    private var preferredIconSize: CGFloat = 48.0
    
    // Adaptive sizing parameters
    private var iconSize: CGFloat {
        if !adaptToContainer {
            return preferredIconSize
        }
        
        // Calculate available height after insets
        let availableHeight = bounds.height - contentInsets.top - contentInsets.bottom
        
        // Scale icon size based on available height
        // Set minimum and maximum sizes
        let minIconSize: CGFloat = 24.0
        let maxIconSize: CGFloat = 60.0
        
        // Use at least 70% of available height for icons
        let calculatedSize = min(maxIconSize, max(minIconSize, availableHeight * 0.7))
        
        return calculatedSize
    }
    
    private var iconSpacing: CGFloat {
        if !adaptToContainer {
            return 14.0
        }
        
        // Calculate available width after insets
        let availableWidth = bounds.width - contentInsets.left - contentInsets.right
        
        // Dynamic number of visible icons based on available width
        let effectiveNumberOfSymbols = min(model.numberOfSymbols, 
                               max(2, Int(availableWidth / (iconSize * 1.5))))
        
        // Calculate spacing to fit icons within available width
        // Ensure spacing is at least 4 points and at most 20 points
        let totalIconWidth = iconSize * CGFloat(effectiveNumberOfSymbols)
        let remainingWidth = availableWidth - totalIconWidth
        let calculatedSpacing = remainingWidth / CGFloat(max(1, effectiveNumberOfSymbols - 1))
        
        return min(20.0, max(4.0, calculatedSpacing))
    }
    
    private let animationDuration: TimeInterval = 0.85
    private let pauseDuration: TimeInterval = 0.45
    
    // Default size when no constraints are provided
    private var defaultHeight: CGFloat { return iconSize + 24.0 }
    private var defaultWidth: CGFloat { 
        return contentWidth + 40.0 // Extra padding
    }
    
    // Content width calculation (used in multiple places)
    private var contentWidth: CGFloat {
        let iconCount = max(model.numberOfSymbols, currentSymbols.count)
        return iconSize * CGFloat(iconCount) + iconSpacing * CGFloat(max(0, iconCount - 1))
    }

    // MARK: - State
    private var currentSymbols: [String] = []
    private var isAnimating: Bool = false
    private var animationTimer: Timer?
    private var collectionViewWidthConstraint: NSLayoutConstraint?
    private var collectionViewHeightConstraint: NSLayoutConstraint?
    private var collectionViewCenterXConstraint: NSLayoutConstraint?
    private var collectionViewCenterYConstraint: NSLayoutConstraint?
    private var blurView: UIVisualEffectView?
    private var vibrancyView: UIVisualEffectView?

    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = SpinnerFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = iconSpacing
        layout.minimumLineSpacing = iconSpacing
        layout.itemSize = CGSize(width: iconSize, height: iconSize)
        
        // Use a defined non-zero frame to avoid ambiguous layout during initialization
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(IconCell.self, forCellWithReuseIdentifier: IconCell.reuseIdentifier)
        cv.isScrollEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.clipsToBounds = false
        cv.alpha = 0 // Start hidden
        cv.isHidden = true // Start hidden
        
        return cv
    }()

    // MARK: - Initialization

    init(model: SFSpinnerModel, 
         initialSymbols: [String]? = nil, 
         contentInsets: UIEdgeInsets = .zero,
         adaptToContainer: Bool = true,
         preferredIconSize: CGFloat = 48.0) {
        self.model = model
        self.contentInsets = contentInsets
        self.adaptToContainer = adaptToContainer
        self.preferredIconSize = preferredIconSize
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 60))
        self.currentSymbols = initialSymbols ?? []
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Provide intrinsic content size to help Auto Layout
    override var intrinsicContentSize: CGSize {
        return CGSize(width: defaultWidth, height: defaultHeight)
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient on layout changes
        if let gradientLayer = objc_getAssociatedObject(self, "gradientLayer") as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
        
        // IMPORTANT: Avoid recursion - don't call updateCollectionViewLayout here
        // Just update constraints directly without triggering new layouts
        updateCollectionViewConstraints(forceLayout: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Safe to update layout here as it's not called from layoutSubviews
        updateCollectionViewLayout()
    }

    // MARK: - SFSpinnerBar Protocol Methods

    func begin(completion: (() -> Void)? = nil) {
        guard !isAnimating else {
            completion?()
            return
        }

        isAnimating = true
        
        // Setup initial symbols if needed
        if currentSymbols.isEmpty || currentSymbols.count != model.numberOfSymbols {
            self.currentSymbols = model.generate()
        }
        
        // First ensure blur is visible with animation
        setupBlurIfNeeded()
        
        // Apply tint color to improve symbol visibility
        let tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0) // Default orange-ish tint
        if let vibrancyView = self.vibrancyView {
            vibrancyView.contentView.tintColor = tintColor
        }
        
        // Prepare collection view
        collectionView.reloadData()
        
        // Update layout parameters
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = CGSize(width: iconSize, height: iconSize)
            flowLayout.minimumInteritemSpacing = iconSpacing
            flowLayout.minimumLineSpacing = iconSpacing
        }
        
        // Update constraints
        updateCollectionViewConstraints(forceLayout: false)
        
        // Force layout to avoid glitching
        layoutIfNeeded()
        
        // Make everything visible
        collectionView.isHidden = false
        collectionView.alpha = 0
        
        // Simple scale animation for blur
        if let blurView = self.blurView {
            blurView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            blurView.alpha = 0
        }
        
        // Animate in using spring for smoother effect
        UIView.animate(withDuration: 0.5, delay: 0, 
                      usingSpringWithDamping: 0.8, 
                      initialSpringVelocity: 0.2, 
                      options: [.allowUserInteraction], 
                      animations: {
            self.blurView?.transform = .identity
            self.blurView?.alpha = 1
            self.collectionView.alpha = 1
        }, completion: { finished in
            if finished {
                self.startCollectionViewAnimationCycle()
                completion?()
            }
        })
    }

    func end(completion: (() -> Void)? = nil) {
        guard isAnimating else {
            completion?()
            return
        }
        
        isAnimating = false
        stopCollectionViewAnimationCycle()
        
        // Animate with better timing function for more stable animation
        UIView.animate(withDuration: 0.4, delay: 0,
                      usingSpringWithDamping: 1.0,
                      initialSpringVelocity: 0.1,
                      options: [.allowUserInteraction, .beginFromCurrentState],
                      animations: {
            self.collectionView.alpha = 0
            self.blurView?.alpha = 0
            self.blurView?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            self.collectionView.isHidden = true
            self.currentSymbols = []
            completion?()
        })
    }

    // MARK: - Private Setup & Layout Methods

    private func setupView() {
        backgroundColor = .clear
        clipsToBounds = false // Allow animation to overflow
        
        // Reset any existing constraints to prevent conflicts
        if collectionViewCenterXConstraint != nil || collectionViewCenterYConstraint != nil {
            NSLayoutConstraint.deactivate([
                collectionViewCenterXConstraint, 
                collectionViewCenterYConstraint, 
                collectionViewHeightConstraint, 
                collectionViewWidthConstraint
            ].compactMap { $0 })
        }
        
        // Add collection view
        addSubview(collectionView)
        
        // Create constraints but don't activate yet - we'll activate them in updateCollectionViewConstraints
        collectionViewCenterXConstraint = collectionView.centerXAnchor.constraint(equalTo: centerXAnchor)
        collectionViewCenterYConstraint = collectionView.centerYAnchor.constraint(equalTo: centerYAnchor)
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: iconSize)
        collectionViewWidthConstraint = collectionView.widthAnchor.constraint(equalToConstant: contentWidth)
        
        // Apply constraints without forcing layout
        updateCollectionViewConstraints(forceLayout: false)
        
        // Set content hugging/compression
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    // New method to update constraints consistently
    private func updateCollectionViewConstraints(forceLayout: Bool = true) {
        // Deactivate existing constraints to prevent conflicts
        NSLayoutConstraint.deactivate([
            collectionViewCenterXConstraint, 
            collectionViewCenterYConstraint, 
            collectionViewHeightConstraint, 
            collectionViewWidthConstraint
        ].compactMap { $0 })
        
        // Update constraint constants
        collectionViewHeightConstraint?.constant = iconSize
        collectionViewWidthConstraint?.constant = contentWidth
        
        // Activate all constraints
        NSLayoutConstraint.activate([
            collectionViewCenterXConstraint,
            collectionViewCenterYConstraint,
            collectionViewHeightConstraint,
            collectionViewWidthConstraint
        ].compactMap { $0 })
        
        // Only force layout if requested and not during layoutSubviews
        if forceLayout {
            // Use invalidateIntrinsicContentSize instead of setNeedsLayout to avoid layout loops
            invalidateIntrinsicContentSize()
        }
    }
    
    private func setupBlurIfNeeded() {
        // Only setup blur once
        guard blurView == nil else { return }
        
        // SIMPLIFIED APPROACH: Use a straightforward blur + vibrancy setup
        // Create blur effect - systemThinMaterialDark works well for this purpose
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 15
        blurEffectView.layer.masksToBounds = true
        blurEffectView.alpha = 0
        
        // Add border for better definition
        blurEffectView.layer.borderWidth = 0.5
        blurEffectView.layer.borderColor = UIColor(white: 1.0, alpha: 0.3).cgColor
        
        // Basic vibrancy effect - using the simpler fill style
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .fill)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        // Keep view hierarchy VERY simple - blur first, then vibrancy
        insertSubview(blurEffectView, at: 0)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        // Simple constraints
        NSLayoutConstraint.activate([
            // Blur takes up whole view
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Vibrancy fills blur content
            vibrancyEffectView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
            vibrancyEffectView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor),
            vibrancyEffectView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor),
            vibrancyEffectView.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor)
        ])
        
        // Store references
        self.blurView = blurEffectView
        self.vibrancyView = vibrancyEffectView
        
        // Put collection view in vibrancy content
        if let vibrancyView = self.vibrancyView {
            collectionView.removeFromSuperview()
            vibrancyView.contentView.addSubview(collectionView)
            
            // Update constraints to use vibrancy content view
            collectionViewCenterXConstraint = collectionView.centerXAnchor.constraint(equalTo: vibrancyView.contentView.centerXAnchor)
            collectionViewCenterYConstraint = collectionView.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor)
            
            // Apply constraints without triggering layout
            updateCollectionViewConstraints(forceLayout: false)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    deinit {
        // Ensure timer is invalidated to prevent memory leaks
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Clear any other potential cycles
        blurView = nil
        vibrancyView = nil
        
        // Ensure proper cleanup of collection view
        collectionView.dataSource = nil
        collectionView.delegate = nil
    }
    
    private func updateCollectionViewLayout() {
        // Update collection view layout for adaptive sizing
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = CGSize(width: iconSize, height: iconSize)
            flowLayout.minimumInteritemSpacing = iconSpacing
            flowLayout.minimumLineSpacing = iconSpacing
            // Just invalidate the layout, don't trigger a full layout cycle
            flowLayout.invalidateLayout()
        }
        
        // Update constraints
        updateCollectionViewConstraints()
        
        // Update section insets to center content
        updateCollectionViewInsets()
    }
    
    private func updateCollectionViewInsets() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        // Only set insets if needed - in most cases, zero insets are fine with our explicit width
        let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.sectionInset = sectionInsets
        
        // Force layout update
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Animation Methods (CollectionView based)
    
    private func startCollectionViewAnimationCycle() {
        animationTimer?.invalidate()
        
        // Start the timer to perform updates with more time for animation to complete
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationDuration + pauseDuration + 0.1,
                                             repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.performCollectionViewAnimationCycle()
        }
        
        // Perform the first cycle after a small delay to ensure initial layout is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.performCollectionViewAnimationCycle()
        }
    }
    
    private func stopCollectionViewAnimationCycle() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func performCollectionViewAnimationCycle() {
        guard isAnimating, !currentSymbols.isEmpty else { return }
        
        // Ensure we're on the main thread for UI updates
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.performCollectionViewAnimationCycle()
            }
            return
        }
        
        let lastSymbol = currentSymbols.last
        
        // Generate the next symbol
        let nextSymbol = model.generateNextSymbol(currentLast: lastSymbol)
        
        // Create a local copy of the updated symbols array
        let newSymbolsArray = Array(currentSymbols.dropFirst()) + [nextSymbol]
        
        // Prepare index paths for animation
        let deleteIndexPath = IndexPath(item: 0, section: 0)
        let insertIndexPath = IndexPath(item: currentSymbols.count - 1, section: 0)
        
        // Update data source right before the animation
        self.currentSymbols = newSymbolsArray
        
        // SAFE: Don't trigger layout recursion by calling layoutIfNeeded
        // Just update the layout directly if needed
        if let flowLayout = collectionView.collectionViewLayout as? SpinnerFlowLayout {
            // Give flow layout what it needs
            flowLayout.prepare()
        }
        
        // Perform batch updates with enhanced spring animation for more stylish movement
        UIView.animate(withDuration: animationDuration, 
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
            // Use performBatchUpdates on main thread
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [deleteIndexPath])
                self.collectionView.insertItems(at: [insertIndexPath])
            })
            
            // Also animate any existing cells for a more cohesive motion
            for cell in self.collectionView.visibleCells {
                cell.alpha = 1.0  // Ensure full opacity
                
                // Apply a very subtle scale bounce to all cells during transition
                UIView.animate(withDuration: self.animationDuration * 0.5, 
                              delay: 0, 
                              options: [.curveEaseOut],
                              animations: {
                    cell.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                }, completion: { _ in
                    UIView.animate(withDuration: self.animationDuration * 0.5) {
                        cell.transform = .identity
                    }
                })
            }
        })
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSymbols.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconCell.reuseIdentifier, for: indexPath) as? IconCell,
              indexPath.item < currentSymbols.count else {
            fatalError("Unable to dequeue IconCell or invalid index")
        }
        
        let symbolName = currentSymbols[indexPath.item]
        cell.configure(symbolName: symbolName)
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: iconSize, height: iconSize)
    }
} 