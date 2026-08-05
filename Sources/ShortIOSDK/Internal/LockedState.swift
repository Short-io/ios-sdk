import Foundation

/// A `Sendable` box guarding a value with an `NSLock`. Swapping in `Mutex` later
/// means changing this file only.
final class LockedState<Value>: @unchecked Sendable {

    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    /// Runs `body` with exclusive access to the stored value.
    func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
