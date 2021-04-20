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
import Uniko

extension ViewModel: ObservableObject {}

struct ContentView: View {
    @StateObject var viewModel: ViewModel<ContentBinder>
    
    var body: some View {
        Text("\(viewModel.count)")
            .padding()
        Button("Start") {
            viewModel.didTapStartButton()
        }
    }
}

enum ContentBinder: Bindable {

    struct Dependency {}

    struct Input {
        let didTapStartButton = PublishRelay<Void>()
    }

    struct State {
        @RxPublished
        fileprivate(set) var count: Int = 0
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
}

extension ViewModel where B == ContentBinder {

    convenience init(dependency: ContentBinder.Dependency) {
        var state = State()
        self.init(input: .init(), state: &state, dependency: .init())
    }

}
