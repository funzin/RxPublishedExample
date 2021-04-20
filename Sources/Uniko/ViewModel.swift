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

public protocol Bindable {
    associatedtype Input
    associatedtype State
    associatedtype Dependency
    
    static func bind(inputObservable: InputObservable<Input>,
                     state: inout State,
                     dependency: Dependency,
                     disposeBag: DisposeBag)
}

public typealias ViewModel<B: Bindable> = BaseViewModel<B> & Bindable

@dynamicMemberLookup
public struct InputWrapper<Input> {
    private let input: Input
    
    init(input: Input) {
        self.input = input
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<Input, PublishRelay<Value>>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath].accept(value)
        }
    }
}

@dynamicMemberLookup
public struct InputObservable<Input> {
    private let input: Input
    
    init(input: Input) {
        self.input = input
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<Input, PublishRelay<Value>>) -> Observable<Value> {
        return input[keyPath: keyPath].asObservable()
    }
}

open class BaseViewModel<B: Bindable>: ViewModelProtocol {
    public let input: InputWrapper<B.Input>
    public private(set) var state: B.State
    private let disposeBag = DisposeBag()
    
    public init(input: B.Input,
                state: inout B.State,
                dependency: B.Dependency) {
        self.input = InputWrapper(input: input)
        self.state = state
        B.bind(inputObservable: InputObservable(input: input),
               state: &state,
               dependency: dependency,
               disposeBag: disposeBag)
    }
}

@dynamicMemberLookup
public protocol ViewModelProtocol {
    associatedtype Input
    associatedtype State
    var input: InputWrapper<Input> { get }
    var state: State { get }
}

extension ViewModelProtocol {
    // state subscript
    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        return state[keyPath: keyPath]
    }

    // input subscript
    public subscript<Value>(dynamicMember keyPath: KeyPath<InputWrapper<Input>, (Value) -> Void>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath](value)
        }
    }

    // input subscript
    public subscript(dynamicMember keyPath: KeyPath<InputWrapper<Input>, (()) -> Void>) -> () -> Void {
        return { [input] in
            input[keyPath: keyPath](())
        }
    }
}

#if canImport(Combine)

extension ObservableObject where Self: ViewModelProtocol {

    public var objectWillChange: AnyPublisher<Void, Never> {
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
