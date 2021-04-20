//
//  ViewModel.swift
//  RxPublishedExample
//
//  Created by nakazawa fumito on 2021/04/17.
//

import SwiftUI
import RxSwift
import RxRelay
import Combine
import RxCombine

protocol Bindable {
    associatedtype Input
    associatedtype State
    associatedtype Dependency
    
    static func bind(input: Input,
                     state: inout State,
                     dependency: Dependency,
                     disposeBag: DisposeBag)
}

typealias ViewModel<B: Bindable> = BaseViewModel<B> & Bindable

class BaseViewModel<B: Bindable> {
    typealias Input = B.Input
    typealias State = B.State
    typealias Dependency = B.Dependency
    
    let input: Input
    private(set) var state: State
    private let disposeBag = DisposeBag()
    
    init(input: Input,
         state: inout State,
         dependency: Dependency) {
        self.input = input
        self.state = state
        B.bind(input: input,
               state: &state,
               dependency: dependency,
               disposeBag: disposeBag)
    }

    var objectWillChange: AnyPublisher<Void, Never> {
        let triggers = Mirror(reflecting: state).children
            .compactMap { $0.value as? RxPublishedType }
            .map { $0.asTriggerObservable() }

        return Observable.merge(triggers)
            .skip(1)
            .map { _ in }
            .asPublisher()
            .catch { _ in Just(()) }
            .eraseToAnyPublisher()
    }
}

@dynamicMemberLookup
protocol BaseObservableObject: ObservableObject {
    associatedtype Input
    associatedtype State
    var input: Input { get }
    var state: State { get }
}

extension BaseObservableObject {
    
    // state subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        return state[keyPath: keyPath]
    }
    
    // input subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<Input, RxRelay<Value>>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath](value)
        }
    }

    // input subscript
    subscript(dynamicMember keyPath: KeyPath<Input, RxRelay<Void>>) -> () -> Void {
        return { [input] in
            input[keyPath: keyPath](())
        }
    }
}
