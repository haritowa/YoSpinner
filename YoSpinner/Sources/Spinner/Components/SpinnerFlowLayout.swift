import UIKit

/// A custom layout that ensures proper animation of deleted and inserted items
final class SpinnerFlowLayout: UICollectionViewFlowLayout {
    
    // Track the inserted index paths during animations
    private var insertedIndexPaths: [IndexPath] = []
    // Add a flag to prevent layout recursion
    private var isPreparingLayout = false
    
    override func prepare() {
        // Guard against recursive layout calls
        guard !isPreparingLayout else { return }
        
        isPreparingLayout = true
        super.prepare()
        
        // Make sure we always have a valid item size
        if itemSize.width <= 0 || itemSize.height <= 0 {
            itemSize = CGSize(width: 48, height: 48)
        }
        
        isPreparingLayout = false
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        // Guard against recursive layout calls
        guard !isPreparingLayout else { return }
        
        isPreparingLayout = true
        super.prepare(forCollectionViewUpdates: updateItems)
        
        // Track which items are being inserted
        insertedIndexPaths = []
        for update in updateItems {
            if update.updateAction == .insert, let indexPath = update.indexPathAfterUpdate {
                insertedIndexPaths.append(indexPath)
            }
        }
        
        isPreparingLayout = false
    }
    
    override func finalizeCollectionViewUpdates() {
        // Guard against recursive calls
        guard !isPreparingLayout else { return }
        
        isPreparingLayout = true
        insertedIndexPaths = []
        super.finalizeCollectionViewUpdates()
        isPreparingLayout = false
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !isPreparingLayout else { return [] }
        
        isPreparingLayout = true
        defer { isPreparingLayout = false }
        
        guard let layoutAttributesArray = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        
        // Make a defensive copy to avoid modifying cached attributes
        // and ensure all elements have valid frames
        let copiedAttributes = layoutAttributesArray.map { 
            attributes -> UICollectionViewLayoutAttributes in
            guard let copy = attributes.copy() as? UICollectionViewLayoutAttributes else {
                return attributes
            }
            
            // Ensure frames are valid
            if copy.frame.width <= 0 || copy.frame.height <= 0 {
                let standardSize = CGSize(width: 48, height: 48)
                copy.size = standardSize
            }
            
            return copy
        }
        
        return copiedAttributes
    }
    
    // Override shouldInvalidateLayout for better layout control
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let oldBounds = collectionView?.bounds else { return true }
        
        // Only invalidate if size actually changed to prevent unnecessary layout cycles
        return oldBounds.size != newBounds.size
    }
    
    // Override these methods to customize animation
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // Guard against recursive layout calls
        guard !isPreparingLayout else { return nil }
        
        isPreparingLayout = true
        defer { isPreparingLayout = false }
        
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        
        // Only if this is a newly inserted item (not just appearing due to scroll)
        if insertedIndexPaths.contains(itemIndexPath) {
            // Start with 0 alpha
            attributes?.alpha = 0.0
            
            // Apply combo transform: slide in from right + slight scale up
            var transform = CGAffineTransform(translationX: 120, y: 0)
            transform = transform.scaledBy(x: 1.1, y: 1.1) // Slightly larger initially
            attributes?.transform = transform
        }
        
        return attributes
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // Guard against recursive layout calls
        guard !isPreparingLayout else { return nil }
        
        isPreparingLayout = true
        defer { isPreparingLayout = false }
        
        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        
        // We know the first item is always the one being deleted
        if itemIndexPath.item == 0 {
            attributes?.alpha = 0.0
            
            // Apply combo transform: slide out to left + slight scale down
            var transform = CGAffineTransform(translationX: -120, y: 0)
            transform = transform.scaledBy(x: 0.9, y: 0.9) // Slightly smaller when exiting
            attributes?.transform = transform
        }
        
        return attributes
    }
} 