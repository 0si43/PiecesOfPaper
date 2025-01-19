//
//  ListOrderStore.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2025/01/19.
//  Copyright © 2025 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

protocol ListOrderStoreProtocol: AnyObject {
    func set(directoryName: String, listOrder: ListOrder)
    func get(directoryName: String) -> ListOrder
}

final class ListOrderStore: ListOrderStoreProtocol {
    private let key = "com.pop.listOrder."
    func set(directoryName: String, listOrder: ListOrder) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(listOrder) else { return }
        UserDefaults.standard.set(data, forKey: key + directoryName)
    }

    func get(directoryName: String) -> ListOrder {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: key + directoryName),
           let listOrder = try? decoder.decode(ListOrder.self, from: data) {
            return listOrder
        } else {
            return ListOrder()
        }
    }
}
