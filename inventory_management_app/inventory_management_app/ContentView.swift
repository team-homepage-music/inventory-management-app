//
//  ContentView.swift
//  inventory_management_app
//
//  Created by 吉田響 on 2025/11/29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Item.updatedAt, order: .reverse)]) private var items: [Item]
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Location.name)]) private var locations: [Location]
    @Query(sort: [SortDescriptor(\Tag.name)]) private var tags: [Tag]

    @State private var selection: Item?
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var selectedLocation: Location?
    @State private var showDisposed = false
    @State private var sortOption: SortOption = .updatedDesc
    @State private var showMasterSheet = false

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                filterBar

                List(selection: $selection) {
                    if filteredItems.isEmpty {
                        ContentUnavailableView("物品がありません", systemImage: "shippingbox", description: Text("追加ボタンで物品を登録してください。"))
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredItems) { item in
                            ItemRow(item: item)
                                .tag(item)
                                .contextMenu { contextMenu(for: item) }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .listStyle(.inset)
                .searchable(text: $searchText, placement: .sidebar)
                .navigationTitle("物品一覧")
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
                .toolbar { toolbar }
            }
            .padding([.leading, .trailing, .top])
        } detail: {
            if let selection, filteredItems.contains(selection) {
                ItemDetailView(item: selection)
            } else {
                ContentUnavailableView("物品を選択", systemImage: "rectangle.on.rectangle")
            }
        }
        .sheet(isPresented: $showMasterSheet) {
            MasterManagementView()
                .frame(minWidth: 520, minHeight: 420)
        }
        .onChange(of: filteredItems) { _, newItems in
            if let current = selection, !newItems.contains(current) {
                selection = newItems.first
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(
                name: "新しい物品",
                category: selectedCategory ?? categories.first,
                location: selectedLocation ?? locations.first
            )
            modelContext.insert(newItem)
            selection = newItem
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let targets = offsets.map { filteredItems[$0] }
            targets.forEach(modelContext.delete)
            if let current = selection, targets.contains(current) {
                selection = filteredItems.first(where: { !targets.contains($0) })
            }
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
            if selection == item {
                selection = filteredItems.first(where: { $0 != item })
            }
        }
    }

    private var filteredItems: [Item] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = items.filter { item in
            if !showDisposed && item.isDisposed {
                return false
            }
            if let selectedCategory, item.category != selectedCategory {
                return false
            }
            if let selectedLocation, item.location != selectedLocation {
                return false
            }
            if trimmed.isEmpty {
                return true
            }

            let haystack = [
                item.name,
                item.notes,
                item.brand,
                item.modelNumber,
                item.serialNumber,
                item.purchaseStore,
                item.color,
                item.accessories,
                item.consumableReplacement,
                item.link,
                item.tags.map(\.name).joined(separator: " ")
            ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

            return haystack.localizedCaseInsensitiveContains(trimmed.lowercased())
        }

        return sort(filtered)
    }

    private func sort(_ items: [Item]) -> [Item] {
        switch sortOption {
        case .updatedDesc:
            items.sorted { $0.updatedAt > $1.updatedAt }
        case .createdDesc:
            items.sorted { $0.createdAt > $1.createdAt }
        case .nameAsc:
            items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameDesc:
            items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: addItem) {
                Label("物品を追加", systemImage: "plus")
            }

            Button(action: { showMasterSheet = true }) {
                Label("マスタ管理", systemImage: "list.bullet.rectangle")
            }

            Picker("ソート", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelStyle(.iconOnly)
            .help("ソート条件を変更")
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("カテゴリ", selection: $selectedCategory) {
                    Text("すべて").tag(Category?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category))
                    }
                }
                Picker("場所", selection: $selectedLocation) {
                    Text("すべて").tag(Location?.none)
                    ForEach(locations) { location in
                        Text(location.name).tag(Optional(location))
                    }
                }
            }

            HStack {
                Toggle("廃棄/売却済も表示", isOn: $showDisposed)
                Spacer()
                Button("リセット") {
                    selectedCategory = nil
                    selectedLocation = nil
                    showDisposed = false
                    searchText = ""
                }
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for item: Item) -> some View {
        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label("削除", systemImage: "trash")
        }
    }
}

private enum SortOption: String, CaseIterable, Identifiable {
    case updatedDesc
    case createdDesc
    case nameAsc
    case nameDesc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .updatedDesc: return "更新日が新しい順"
        case .createdDesc: return "登録日が新しい順"
        case .nameAsc: return "名前 A→Z"
        case .nameDesc: return "名前 Z→A"
        }
    }
}

private struct ItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name.isEmpty ? "名称未設定" : item.name)
                    .fontWeight(.semibold)
                if item.isDisposed {
                    Label("廃棄/売却済", systemImage: "archivebox")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.updatedAt, format: Date.FormatStyle(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if let category = item.category {
                    Label(category.name, systemImage: "square.grid.2x2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let location = item.location {
                    Label(location.name, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: Item

    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Location.name)]) private var locations: [Location]
    @Query(sort: [SortDescriptor(\Tag.name)]) private var tags: [Tag]

    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("名前（必須）", text: $item.name)
                    .onChange(of: item.name) { touch() }

                Picker("カテゴリ", selection: $item.category) {
                    Text("未選択").tag(Category?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category))
                    }
                }

                Picker("所有場所", selection: $item.location) {
                    Text("未選択").tag(Location?.none)
                    ForEach(locations) { location in
                        Text(location.name).tag(Optional(location))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("タグ")
                    if tags.isEmpty {
                        Text("タグがまだ登録されていません。マスタ管理から追加できます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tags) { tag in
                            Toggle(isOn: Binding(
                                get: { item.tags.contains(tag) },
                                set: { isOn in
                                    if isOn {
                                        if !item.tags.contains(tag) {
                                            item.tags.append(tag)
                                        }
                                    } else {
                                        item.tags.removeAll { $0 == tag }
                                    }
                                    touch()
                                }
                            )) {
                                Text(tag.name)
                            }
                        }
                    }
                }

                TextField("メモ", text: optionalStringBinding(\.notes), axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("詳細情報") {
                TextField("ブランド / メーカー", text: optionalStringBinding(\.brand))
                TextField("型番", text: optionalStringBinding(\.modelNumber))
                TextField("シリアル番号", text: optionalStringBinding(\.serialNumber))
                optionalDateField("購入日", keyPath: \.purchaseDate)
                HStack {
                    TextField("購入価格（数字のみ）", text: doubleStringBinding(\.purchasePrice))
                        .textFieldStyle(.roundedBorder)
                    Text("円")
                        .foregroundStyle(.secondary)
                }
                TextField("購入店", text: optionalStringBinding(\.purchaseStore))
                optionalDateField("保証期限", keyPath: \.warrantyExpiration)
                TextField("サイズ・寸法", text: optionalStringBinding(\.dimensions))
                TextField("重量", text: optionalStringBinding(\.weight))
                TextField("カラー", text: optionalStringBinding(\.color))
                TextField("付属品", text: optionalStringBinding(\.accessories))
                TextField("消耗品の交換時期", text: optionalStringBinding(\.consumableReplacement))
                TextField("リンク（URL）", text: optionalStringBinding(\.link))
            }

            Section("運用情報") {
                Toggle("廃棄／売却済", isOn: $item.isDisposed)
                    .onChange(of: item.isDisposed) { _, newValue in
                        item.disposedAt = newValue ? (item.disposedAt ?? .now) : nil
                        touch()
                    }
                if item.isDisposed {
                    optionalDateField("廃棄／売却日", keyPath: \.disposedAt)
                }

                LabeledContent("登録日") {
                    Text(item.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("最終更新日") {
                    Text(item.updatedAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(item.name.isEmpty ? "物品詳細" : item.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .alert("この物品を削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                modelContext.delete(item)
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func optionalStringBinding(_ keyPath: ReferenceWritableKeyPath<Item, String?>) -> Binding<String> {
        Binding(
            get: { item[keyPath: keyPath] ?? "" },
            set: { newValue in
                item[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
                touch()
            }
        )
    }

    private func doubleStringBinding(_ keyPath: ReferenceWritableKeyPath<Item, Double?>) -> Binding<String> {
        Binding(
            get: { item[keyPath: keyPath].map { String($0) } ?? "" },
            set: { newValue in
                item[keyPath: keyPath] = Double(newValue)
                touch()
            }
        )
    }

    private func dateBinding(_ keyPath: ReferenceWritableKeyPath<Item, Date?>) -> Binding<Date> {
        Binding(
            get: { item[keyPath: keyPath] ?? .now },
            set: { newValue in
                item[keyPath: keyPath] = newValue
                touch()
            }
        )
    }

    private func optionalDateField(_ title: String, keyPath: ReferenceWritableKeyPath<Item, Date?>) -> some View {
        HStack {
            DatePicker(title, selection: dateBinding(keyPath), displayedComponents: .date)
            Spacer()
            Button(item[keyPath: keyPath] == nil ? "設定" : "クリア") {
                if item[keyPath: keyPath] == nil {
                    item[keyPath: keyPath] = .now
                } else {
                    item[keyPath: keyPath] = nil
                }
                touch()
            }
            .buttonStyle(.borderless)
        }
    }

    private func touch() {
        item.updatedAt = .now
    }
}

private struct MasterManagementView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Label("閉じる", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }

            TabView {
                CategoryManagementView()
                    .tabItem {
                        Label("カテゴリ", systemImage: "square.grid.2x2")
                    }

                LocationManagementView()
                    .tabItem {
                        Label("場所", systemImage: "mappin.and.ellipse")
                    }

                TagManagementView()
                    .tabItem {
                        Label("タグ", systemImage: "tag")
                    }
            }
        }
        .padding()
    }
}

private struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ")
                .font(.title2)
                .bold()
            HStack {
                TextField("カテゴリ名を追加", text: $newName)
                    .onSubmit(addCategory)
                Button("追加", action: addCategory)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            List {
                ForEach(categories) { category in
                    TextField("名称", text: Binding(
                        get: { category.name },
                        set: { category.name = $0 }
                    ))
                }
                .onDelete(perform: deleteCategory)
            }
        }
        .padding()
    }

    private func addCategory() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = Category(name: trimmed)
        modelContext.insert(category)
        newName = ""
    }

    private func deleteCategory(at offsets: IndexSet) {
        offsets.map { categories[$0] }.forEach(modelContext.delete)
    }
}

private struct LocationManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Location.name)]) private var locations: [Location]
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所有場所")
                .font(.title2)
                .bold()
            HStack {
                TextField("場所を追加", text: $newName)
                    .onSubmit(addLocation)
                Button("追加", action: addLocation)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            List {
                ForEach(locations) { location in
                    TextField("名称", text: Binding(
                        get: { location.name },
                        set: { location.name = $0 }
                    ))
                }
                .onDelete(perform: deleteLocation)
            }
        }
        .padding()
    }

    private func addLocation() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let location = Location(name: trimmed)
        modelContext.insert(location)
        newName = ""
    }

    private func deleteLocation(at offsets: IndexSet) {
        offsets.map { locations[$0] }.forEach(modelContext.delete)
    }
}

private struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Tag.name)]) private var tags: [Tag]
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ")
                .font(.title2)
                .bold()
            HStack {
                TextField("タグを追加", text: $newName)
                    .onSubmit(addTag)
                Button("追加", action: addTag)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            List {
                ForEach(tags) { tag in
                    TextField("名称", text: Binding(
                        get: { tag.name },
                        set: { tag.name = $0 }
                    ))
                }
                .onDelete(perform: deleteTag)
            }
        }
        .padding()
    }

    private func addTag() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let tag = Tag(name: trimmed)
        modelContext.insert(tag)
        newName = ""
    }

    private func deleteTag(at offsets: IndexSet) {
        offsets.map { tags[$0] }.forEach(modelContext.delete)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Category.self, Location.self, Tag.self], inMemory: true)
}
