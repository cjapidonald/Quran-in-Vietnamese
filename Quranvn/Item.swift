//
//  Item.swift
//  Quranvn
//
//  Created by Donald Cjapi on 11/10/25.
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
