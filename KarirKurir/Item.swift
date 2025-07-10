//
//  Item.swift
//  KarirKurir
//
//  Created by Hayya U on 10/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
