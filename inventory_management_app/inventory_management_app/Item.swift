//
//  Item.swift
//  inventory_management_app
//
//  Created by 吉田響 on 2025/11/29.
//

import Foundation
import SwiftData

enum Condition: String, Codable, CaseIterable, Identifiable {
    case brandNew = "新品"
    case good = "良好"
    case normal = "普通"
    case deteriorated = "劣化"
    case broken = "壊れている"

    var id: String { rawValue }
}

@Model
final class Category: Hashable {
    var name: String
    @Relationship(inverse: \Item.category) var items: [Item]? = []

    init(name: String) {
        self.name = name
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
final class Location: Hashable {
    var name: String
    @Relationship(inverse: \Item.location) var items: [Item]? = []

    init(name: String) {
        self.name = name
    }

    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
final class Tag: Hashable {
    var name: String
    @Relationship(inverse: \Item.tags) var items: [Item]? = []

    init(name: String) {
        self.name = name
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
final class Item: Hashable {
    // 基本情報
    var name: String
    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .nullify) var location: Location?
    var notes: String?
    @Relationship(deleteRule: .nullify) var tags: [Tag] = []

    // 詳細情報
    var brand: String?
    var modelNumber: String?
    var serialNumber: String?
    var purchaseDate: Date?
    var purchaseStore: String?
    var purchasePrice: Double?
    var warrantyExpiration: Date?
    var dimensions: String?
    var weight: String?
    var color: String?
    var condition: Condition
    var accessories: String?
    var consumableReplacement: String?
    var link: String?

    // 運用情報
    var createdAt: Date
    var updatedAt: Date
    var isDisposed: Bool
    var disposedAt: Date?

    init(
        name: String,
        category: Category? = nil,
        location: Location? = nil,
        notes: String? = nil,
        tags: [Tag] = [],
        brand: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        purchaseDate: Date? = nil,
        purchaseStore: String? = nil,
        purchasePrice: Double? = nil,
        warrantyExpiration: Date? = nil,
        dimensions: String? = nil,
        weight: String? = nil,
        color: String? = nil,
        condition: Condition = .good,
        accessories: String? = nil,
        consumableReplacement: String? = nil,
        link: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDisposed: Bool = false,
        disposedAt: Date? = nil
    ) {
        self.name = name
        self.category = category
        self.location = location
        self.notes = notes
        self.tags = tags
        self.brand = brand
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.purchaseStore = purchaseStore
        self.purchasePrice = purchasePrice
        self.warrantyExpiration = warrantyExpiration
        self.dimensions = dimensions
        self.weight = weight
        self.color = color
        self.condition = condition
        self.accessories = accessories
        self.consumableReplacement = consumableReplacement
        self.link = link
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDisposed = isDisposed
        self.disposedAt = disposedAt
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
