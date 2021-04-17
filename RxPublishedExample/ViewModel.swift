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
final class StateWrapper<State> {
    private let state: State
    init(state: State) {
        self.state = state
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        return state[keyPath: keyPath]
    }
}

@dynamicMemberLookup
final class InputWrapper<Input> {
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
    let state: StateWrapper<State>
    private let disposeBag = DisposeBag()
    
    init(input: Input,
         state: inout State,
         dependency: Dependency) {
        self.input = InputWrapper(input: input)
        self.state = StateWrapper(state: state)
        B.bind(inputObservable: InputObservable(input: input),
               state: &state,
               dependency: dependency,
               disposeBag: disposeBag)
    }
}

@dynamicMemberLookup
protocol BaseObservableObject: ObservableObject {
    associatedtype Input
    associatedtype State
    var input: InputWrapper<Input> { get }
    var state: StateWrapper<State> { get }
}

extension BaseObservableObject {
    
    // state subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<StateWrapper<State>, Value>) -> Value {
        return state[keyPath: keyPath]
    }
    
    // input subscript
    subscript<Value>(dynamicMember keyPath: KeyPath<InputWrapper<Input>, (Value) -> Void>) -> (Value) -> Void {
        return { [input] value in
            input[keyPath: keyPath](value)
        }
    }
}
