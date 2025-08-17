//
//  DataController.swift
//  Tracker
//
//  Created by Michael on 8/2/25.
//

import CoreData

class DataController: ObservableObject {
    let container: NSPersistentCloudKitContainer
    
    @Published var selectedFilter: Filter? = Filter.all
    
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    init(inMemory: Bool = false) {
        // name should be the same as xcdatamodeld filename
        container = NSPersistentCloudKitContainer(name: "Main")
        
        if inMemory {
            // This is a special URL which ensures no data is saved
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        // Creates and loads data store
        container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    
    func createSampleData() {
        // This is the live data loaded in RAM right now
        // Data will only be written to disk when you call save
        let viewContext = container.viewContext
        
        for i in 1...5 {
            // When creating instances of data types like Tag and Issue, we specify
            // which context they are made inside. This helps CoreData know how to save them.
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(i)"
            
            for j in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(i)-\(j)"
                issue.content = "Description goes here"
                issue.creationDate = .now
                issue.completed = Bool.random()
                issue.priority = Int16.random(in: 0...2)
                tag.addToIssues(issue)
                
            }
        }
        
        // Tells CoreData to write data to storage.
        // If this is in-memory, it won't last long, but it can also be permanent storage.
        try? viewContext.save()
    }
    
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        // This announces that an object is about to be changed.
        objectWillChange.send()
        container.viewContext.delete(object)
        save()
    }
    
    // This is marked private since it will only be used in testing
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        // Helps us know what was deleted
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        // Executes a batch delete
        // Need type casting since .execute() could be any request
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            // delete.result is an array of deleted object IDs. We put it in a
            // dictionary and type cast the values since they must be object IDs
            // (we asked for object IDs with .resultTypeObjectIDs
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            // This takes the dictionary and merges the changes with the view context
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
    
    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1)
        
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2)
        
        save()
    }
}
