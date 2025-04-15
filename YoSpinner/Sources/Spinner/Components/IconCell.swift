import UIKit
// For internal use, we can safely use UIKit because it's part of the same module
// and will be part of the compiled library

/// Simple cell to display a single icon image.
final class IconCell: UICollectionViewCell {
    static let reuseIdentifier = "IconCell"
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.tintAdjustmentMode = .normal
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        
        // Debug: Add background to visualize cell bounds
        // contentView.backgroundColor = UIColor.red.withAlphaComponent(0.3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        
        // Maintain correct tint on reuse
        imageView.tintColor = .white
    }
    
    func configure(symbolName: String) {
        // Configure with a larger weight and proper rendering mode for vibrancy 
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        let image = UIImage(systemName: symbolName, withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        imageView.image = image
        
        // Make sure everything is clear to work with vibrancy
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        // Use white tint which will be affected by the vibrancy effect
        imageView.tintColor = .white
        imageView.tintAdjustmentMode = .normal
    }
    
    // Critical for vibrancy to work properly
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            // Reset tint to be sure it's applied after moving in view hierarchy
            imageView.tintColor = .white
        }
    }
} 