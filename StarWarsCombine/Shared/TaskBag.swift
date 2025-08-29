// Shared/TaskBag.swift

import Combine
import Foundation

/// A tiny cancellation bag for Combine.
/// Usage:
///   private let bag = TaskBag()
///   publisher.sink { ... }.store(in: bag)
public final class TaskBag {
    private var cancellables = Set<AnyCancellable>()
    private let lock = NSLock()

    public init() {}

    public func insert(_ cancellable: AnyCancellable) {
        lock.lock()
        cancellables.insert(cancellable)
        lock.unlock()
    }

    public func cancelAll() {
        lock.lock()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        lock.unlock()
    }

    deinit {
        cancelAll()
    }
}

extension AnyCancellable {
    public func store(in bag: TaskBag) {
        bag.insert(self)
    }
}
