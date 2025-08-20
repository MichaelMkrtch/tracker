//
//  SidebarView.swift
//  Tracker
//
//  Created by Michael on 8/15/25.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var dataController: DataController
    let smartFilters: [Filter] = [.all, .recent]
    
    // @FetchRequest ensures SwiftUI updates automatically as tags change
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var tags: FetchedResults<Tag>
    
    @State private var tagToRename: Tag?
    @State private var renamingTag = false
    @State private var tagName = ""
    
    @State private var showingAwards = false
    
    var tagFilters: [Filter] {
        tags.map { tag in
            Filter(id: tag.tagID, name: tag.tagName, icon: "tag", tag: tag)
        }
    }
    
    var body: some View {
        List(selection: $dataController.selectedFilter) {
            Section("Smart Filters") {
                ForEach(smartFilters, content: SmartFilterRow.init)
            }
            
            Section("Tags") {
                ForEach(tagFilters) { filter in
                    UserFilterRow(filter: filter, rename: rename, delete: delete)
                }
                .onDelete(perform: delete)
            }
        }
        .toolbar {
            SidebarViewToolbar(showingAwards: $showingAwards)
        }
        .alert("Rename tag", isPresented: $renamingTag) {
            Button("Ok", action: completeRename)
            Button("Cancel", role: .cancel) { }
            TextField("New name", text: $tagName)
        }
        .sheet(isPresented: $showingAwards, content: AwardsView.init)
        .navigationTitle("Filters")
    }
    
    func rename(_ filter: Filter) {
        tagToRename = filter.tag
        tagName = filter.name
        renamingTag = true
    }
    
    func completeRename() {
        tagToRename?.name = tagName
        dataController.save()
    }
    
    func delete(_ filter: Filter) {
        // We can determine which filters are user-created by whether they
        // have tags attached to them (smart filters do not).
        guard let tag = filter.tag else { return }
        dataController.delete(tag)
        dataController.save()
    }
    
    // Delete method for swipe to delete
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = tags[offset]
            dataController.delete(item)
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(DataController.preview)
}
