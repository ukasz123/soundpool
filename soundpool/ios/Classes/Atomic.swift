//
//  Atomic.swift
//
// Originally found on SO:
// https://stackoverflow.com/a/55064703
//
//  Created by Lukasz Huculak on 05/06/2020.
//

import Foundation

final class Atomic<T> {

    private let sema = DispatchSemaphore(value: 1)
    private var _value: T

    init (_ value: T) {
        _value = value
    }

    var value: T {
        get {
            sema.wait()
            defer {
                sema.signal()
            }
            return _value
        }
        set {
            sema.wait()
            _value = newValue
            sema.signal()
        }
    }

    func swap(_ value: T) -> T {
        sema.wait()
        let v = _value
        _value = value
        sema.signal()
        return v
    }
}

extension Atomic where T == Int {
    
    func increment() -> Int {
        return increment(n: 1)
    }

    func increment(n: Int) -> Int {
        sema.wait()
        let v = _value + n
        _value = v
        sema.signal()
        return v
    }
}
