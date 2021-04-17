//
//  RxPublishedExampleApp.swift
//  RxPublishedExample
//
//  Created by nakazawa fumito on 2021/04/17.
//

import SwiftUI

@main
struct RxPublishedExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(dependency: .init()))
        }
    }
}
