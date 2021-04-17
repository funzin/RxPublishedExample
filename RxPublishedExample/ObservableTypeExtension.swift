//
//  ObservableTypeExtension.swift
//  RxPublishedExample
//
//  Created by nakazawa fumito on 2021/04/17.
//

import RxRelay
import RxSwift
import Combine

extension ObservableType {
    func assign(to published: inout Self) {
        published = self
    }
}
