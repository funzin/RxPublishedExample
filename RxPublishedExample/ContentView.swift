//
//  ContentView.swift
//  RxPublishedExample
//
//  Created by nakazawa fumito on 2021/04/17.
//

import SwiftUI
import RxSwift
import RxRelay
import RxCombine
import Combine

struct ContentView<VM: ContentViewModelProtocol>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        Text("\(viewModel.count)")
            .padding()
        Button("Start") {
            viewModel.didTapStartButton()
        }
    }
}

protocol ContentViewModelProtocol: BaseObservableObject where State == ContentViewModel.State,
                                                              Input == ContentViewModel.Input {
}

final class ContentViewModel: ViewModel<ContentViewModel>, ContentViewModelProtocol {
    
    struct Dependency {}
    
    struct Input {
        let didTapStartButton = PublishRelay<Void>()
    }
    
    struct State {
        @RxPublished
        fileprivate(set) var count: Int = 0
    }
    
    convenience init(dependency: Dependency) {
        var state = State()
        self.init(input: .init(), state: &state, dependency: .init())
    }
    
    static func bind(inputObservable: InputObservable<Input>,
                     state: inout State,
                     dependency: Dependency,
                     disposeBag: DisposeBag) {
        inputObservable.didTapStartButton
            .flatMapLatest {
                Observable<Int>.interval(.milliseconds(100), scheduler: MainScheduler.instance)
            }
            .assign(to: &state.$count)
    }

    override var objectWillChange: AnyPublisher<Void, Never> {
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

