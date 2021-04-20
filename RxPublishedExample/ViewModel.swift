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
    
    static func bind(inputObservable: InputObservable<Input>,
                     state: inout State,
                     dependency: Dependency,
                     disposeBag: DisposeBag)
}

typealias ViewModel<B: Bindable> = BaseViewModel<B> & Bindable

@dynamicMemberLookup
struct InputWrapper<Input> {
    private let input: Input
    
    init(input: Input) {
        self.input = input
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<Input, PublishRelay<Value>>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath].accept(value)
        }
    }
}

@dynamicMemberLookup
final class InputObservable<Input> {
    private let input: Input
    
    init(input: Input) {
        self.input = input
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<Input, PublishRelay<Value>>) -> Observable<Value> {
        return input[keyPath: keyPath].asObservable()
    }
}

class BaseViewModel<B: Bindable> {
    typealias Input = B.Input
    typealias State = B.State
    typealias Dependency = B.Dependency
    
    let input: InputWrapper<Input>
    private(set) var state: State
    private let disposeBag = DisposeBag()
    
    init(input: Input,
         state: inout State,
         dependency: Dependency) {
        self.input = InputWrapper(input: input)
        self.state = state
        B.bind(inputObservable: InputObservable(input: input),
               state: &state,
               dependency: dependency,
               disposeBag: disposeBag)
    }
}

@dynamicMemberLookup
protocol ViewModelProtocol {
    associatedtype Input
    associatedtype State
    var input: InputWrapper<Input> { get }
    var state: State { get }
}

extension ViewModelProtocol {
    // state subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        return state[keyPath: keyPath]
    }

    // input subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<InputWrapper<Input>, (Value) -> Void>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath](value)
        }
    }

    // input subscript
    subscript(dynamicMember keyPath: KeyPath<InputWrapper<Input>, (()) -> Void>) -> () -> Void {
        return { [input] in
            input[keyPath: keyPath](())
        }
    }
}

#if canImport(Combine)

extension ObservableObject where Self: ViewModelProtocol {

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

#endif
