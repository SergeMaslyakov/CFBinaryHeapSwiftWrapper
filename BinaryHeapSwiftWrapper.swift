import Foundation

/// Predefined CFBinaryHeapCallBacks structure containing a set
/// of callbacks appropriate for use when the values in a CFBinaryHeap
/// are all CFString types.
//private let heapObjectCallBacks = kCFStringBinaryHeapCallBacks

private let heapObjectCallBacks = CFBinaryHeapCallBacks(
    version: 0,
    retain: nil,
    release: nil,
    copyDescription: nil,
    compare: { firstPtr, secondPtr, _ in
        let first = firstPtr?.heapObject
        let second = secondPtr?.heapObject

        if (first == nil && second == nil) || first?.priority == second?.priority {
            return .compareEqualTo
        }

        guard let first, let second else {
            return first != nil ? .compareGreaterThan : .compareLessThan
        }

        return first.priority > second.priority ? .compareGreaterThan : .compareLessThan
    }
)

private extension UnsafeRawPointer {
    var heapObject: HeapObject {
        Unmanaged<HeapObject>.fromOpaque(self).takeUnretainedValue()
    }
}

private extension HeapObject {
    var rawPointer: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }
}

final class HeapObject {
    var priority: Int

    init(priority: Int) {
        self.priority = priority
    }
}

final class BinaryHeapSwiftWrapper {
    private let capacity: Int
    private let callbacks: CFBinaryHeapCallBacks

    private lazy var binaryHeap: CFBinaryHeap = {
        let callBacksPtr = UnsafeMutablePointer<CFBinaryHeapCallBacks>.allocate(capacity: 1)
        callBacksPtr.initialize(to: callbacks)
        defer { callBacksPtr.deallocate() }

        return CFBinaryHeapCreate(
            nil,
            capacity,
            callBacksPtr,
            nil
        )
    }()

    init(capacity: Int) {
        self.capacity = capacity
        self.callbacks = heapObjectCallBacks
    }

    func addValue(_ object: HeapObject) {
        CFBinaryHeapAddValue(binaryHeap, object.rawPointer)
    }

    func containsValue(_ object: HeapObject) -> Bool {
        CFBinaryHeapContainsValue(binaryHeap, object.rawPointer)
    }

    func getCount() -> Int {
        CFBinaryHeapGetCount(binaryHeap)
    }

    func getCountOfValue(_ object: HeapObject) -> Int {
        CFBinaryHeapGetCountOfValue(binaryHeap, object.rawPointer)
    }

    func getMinimum() -> HeapObject? {
        CFBinaryHeapGetMinimum(binaryHeap)?.heapObject
    }

    /// The values in the array are ordered from least to greatest
    func getValues() -> [HeapObject] {
        let count = CFBinaryHeapGetCount(binaryHeap)
        let arrayOfPointers = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: count)
        defer { arrayOfPointers.deallocate() }

        CFBinaryHeapGetValues(binaryHeap, arrayOfPointers)

        var objects: [HeapObject] = []
        for stride in 0..<count {
            if let rawPointer = (arrayOfPointers + stride).pointee {
                objects.append(rawPointer.heapObject)
            }
        }

        return objects
    }

    func removeAll() {
        CFBinaryHeapRemoveAllValues(binaryHeap)
    }

    func removeMinimumValue() {
        CFBinaryHeapRemoveMinimumValue(binaryHeap)
    }
}
