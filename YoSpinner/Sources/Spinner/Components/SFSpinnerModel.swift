import Foundation

/// Holds the configuration and logic for generating symbols for the spinner bar.
public struct SFSpinnerModel {
    let numberOfSymbols: Int
    let symbolPool: [String]

    public init(numberOfSymbols: Int = 3, symbolPool: [String]) {
        self.numberOfSymbols = numberOfSymbols
        self.symbolPool = symbolPool
    }

    /// Generates a new list of unique SFSymbol names.
    func generate() -> [String] {
        guard symbolPool.count >= numberOfSymbols else {
            fatalError("Symbol pool must contain at least numberOfSymbols unique symbols")
        }
        // Use a Set to ensure uniqueness while selecting symbols
        var uniqueSymbols = Set<String>()
        var shuffledPool = symbolPool.shuffled()
        
        // Keep adding symbols until we have the required number
        while uniqueSymbols.count < numberOfSymbols && !shuffledPool.isEmpty {
            if let symbol = shuffledPool.popLast() {
                uniqueSymbols.insert(symbol)
            }
        }
        
        // If we still don't have enough symbols, use the original pool
        if uniqueSymbols.count < numberOfSymbols {
            uniqueSymbols = uniqueSymbols.union(Array(symbolPool.prefix(numberOfSymbols - uniqueSymbols.count)))
        }
        
        return Array(uniqueSymbols)
    }
    
    /// Generates a single new symbol, trying not to repeat the last one if possible.
    func generateNextSymbol(currentLast: String?) -> String {
        var potentialNext = symbolPool.randomElement() ?? "questionmark.circle.fill"
        if symbolPool.count > 1, let last = currentLast, potentialNext == last {
            // Try one more time to get a different one
            potentialNext = symbolPool.filter { $0 != last }.randomElement() ?? "questionmark.circle.fill"
        }
        return potentialNext
    }
} 