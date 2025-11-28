//
//  Item.swift
//  inventory_management_app
//
//  Created by 吉田響 on 2025/11/29.
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
