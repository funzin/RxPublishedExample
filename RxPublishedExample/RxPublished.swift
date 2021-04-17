//
//  RxPublished.swift
//  RxPublishedExample
//
//  Created by nakazawa fumito on 2021/04/17.
//

import RxSwift
import RxRelay

@propertyWrapper
struct RxPublished<Value> {
    private let relay: BehaviorRelay<Value>
    private let disposeBag = DisposeBag()
    
    var wrappedValue: Value {
        get {
            relay.value
        }
        set {
            relay.accept(newValue)
        }
    }
    
    var projectedValue: Observable<Value> {
        get {
            relay.asObservable()
        }
        set {
            newValue
                .bind(to: relay)
                .disposed(by: disposeBag)
        }
    }
    
    init(relay: BehaviorRelay<Value>) {
        self.relay = relay
    }
    
    init(wrappedValue initialValue: Value) {
        self.relay = .init(value: initialValue)
    }
}
