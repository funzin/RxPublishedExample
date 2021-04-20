//
//  RxRelay.swift
//  RxPublishedExample
//
//  Created by inami yasuhiro on 2021/04/20.
//

import Foundation
import RxSwift
import RxRelay

/// Simple wrapper around `PublishRelay` for skipping redundant `accept` and `asObservable`.
public struct RxRelay<Element>: ObservableType {
    let relay: PublishRelay<Element>

    public init() {
        self.relay = .init()
    }

    public init(relay: PublishRelay<Element>) {
        self.relay = relay
    }

    public func callAsFunction(_ value: Element) {
        relay.accept(value)
    }

    public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Self.Element == Observer.Element {
        relay.subscribe(observer)
    }
}

extension RxRelay where Element == Void {
    public func callAsFunction() {
        relay.accept(())
    }
}
