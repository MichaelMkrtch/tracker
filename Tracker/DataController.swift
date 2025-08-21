//
//  DataController.swift
//  Tracker
//
//  Created by Michael on 8/2/25.
//

import CoreData

enum SortType: String {
    // Mapping to CoreData attribute names
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}

/// An environment singleton responsible for managing our CoreData stack, including
/// counting fetch requests, tracking orders, and dealing with sample data.
class DataController: ObservableObject {

    /// The lone CloudKit container used to store our data.
    let container: NSPersistentCloudKitContainer

    @Published var selectedFilter: Filter? = Filter.all
    @Published var selectedIssue: Issue?

    @Published var filterText = ""
    @Published var filterTokens = [Tag]()

    @Published var filterEnabled = false
    @Published var filterPriority = -1
    @Published var filterStatus = Status.all
    @Published var sortType = SortType.dateCreated
    @Published var sortNewestFirst = true

    private var saveTask: Task<Void, Error>?

    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()

    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else { return [] }

        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)

        let request = Tag.fetchRequest()

        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }

        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }

    /// Initializes a data controller, either in memory (testing use) or on
    /// permanent storage (regular app runs).
    ///
    /// Defaults to permanent storage.
    /// - Parameter inMemory: Whether to store this data in temporary memory or not.
    init(inMemory: Bool = false) {
        // name should be the same as xcdatamodeld filename
        container = NSPersistentCloudKitContainer(name: "Main")

        // For testing and previewing purposes, we create a temporary
        // in-memory DB by writing to /dev/null. This ensures data is
        // destroyed after the app finishes running.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }

        // Without this, users would have to exit and relaunch app for new data to sync
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Tells CoreData to merge changes by property, rather than just replacing
        // the entire cloud object with the local object. Allows granular data updates
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // One more step is necessary to ensure data sync works well when there are
        // simultaneous changes from multiple devices.
        // This watches iCloud for any changes to our data to make sure local UI is in
        // sync when a remote change occurs.
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // When a change to the data is detected, this calls remoteStoreChanged, which announces
        // the change to SwiftUI to update the UI.
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main,
            using: remoteStoreChanged)

        // Creates and loads data store
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }

    // Announces when changes occur to data
    func remoteStoreChanged(_ notification: Notification) {
        objectWillChange.send()
    }

    func createSampleData() {
        // This is the live data loaded in RAM right now
        // Data will only be written to disk when you call save
        let viewContext = container.viewContext

        for tagCounter in 1...5 {
            // When creating instances of data types like Tag and Issue, we specify
            // which context they are made inside. This helps CoreData know how to save them
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(tagCounter)"

            for issueCounter in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(tagCounter)-\(issueCounter)"
                issue.content = String(localized: "Description goes here")
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

    /// Saves our CoreData context iff there are changes. This silently ignores
    /// any errors caused by saving, which is fine because all our attributes are optional.
    func save() {
        // If save() is called, we might as well cancel any queued save tasks
        // since this function call will perform the save.
        saveTask?.cancel()

        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    func queueSave() {
        saveTask?.cancel()

        // @MainActor tells the Task that the code block must run on the MainActor
        // While CoreData is designed to run in a multithreaded environment, a managed
        // object should not be passed between threads
        saveTask = Task { @MainActor in
            // Canceling a task causes .sleep to throw, so we need try here. It also exits
            // this block without calling save, achieving the desired behavior
            try await Task.sleep(for: .seconds(3))
            save()
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

        // ⚠️ When performing a batch delete, we need to make sure we read the
        // result then merge all changes from that result back into our
        // live view context so that the two stay in sync.
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

    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []

        let allTagsSet = Set(allTags)
        let difference = allTagsSet.symmetricDifference(issue.issueTags)

        return difference.sorted()
    }

    /// Runs a fetch request with various predicates that filter the user's issues
    /// based on tag, title, context text, search tokens, priority, and
    /// completion status.
    /// - Returns: An array of all matching issues.
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all
        var predicates = [NSPredicate]()

        if let tag = filter.tag {
            // Selects issues with the chosen tag
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(
                format: "modificationDate > %@",
                filter.minModificationDate as NSDate
            )
            predicates.append(datePredicate)
        }

        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)

        if trimmedFilterText.isEmpty == false {
            // CONTAINS[c] is case-insensitive
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            let combinedPredicate = NSCompoundPredicate(
                orPredicateWithSubpredicates: [titlePredicate, contentPredicate]
            )

            predicates.append(combinedPredicate)
        }

        if filterTokens.isEmpty == false {
            for filterToken in filterTokens {
                let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
                predicates.append(tokenPredicate)
            }
        }

        if filterEnabled {
            if filterPriority >= 0 {
                // %d is for numbers
                let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
                predicates.append(priorityFilter)
            }

            if filterStatus != .all {
                let lookForClosed = filterStatus == .closed
                // Swift Bool needs to be wrapped in NSNumber to be compatible due to Obj-C
                let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
                predicates.append(statusFilter)
            }
        }

        let request = Issue.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        // sortType.rawValue reads out the underlying raw value in the enum
        request.sortDescriptors = [NSSortDescriptor(
            key: sortType.rawValue,
            ascending: sortNewestFirst)]

        let allIssues = (try? container.viewContext.fetch(request)) ?? []
        return allIssues
    }

    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = "New tag"
        save()
    }

    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = "New Issue"
        issue.creationDate = .now
        issue.priority = 1

        // If we are currently browsing a user-created tag and create an issue,
        // immediately add this new issue to the tag. Otherwise, it won't appear in
        // the list of issues we see.
        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }

        save()

        selectedIssue = issue
    }

    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
            // return true if user added a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        case "closed":
            // return true if user closed a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        case "tags":
            // return true if user created a certain number of tags
            let fetchRequest = Tag.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        default:
            // an unknown reward criterion which should never occur
//            fatalError("Unknown award criterion: \(award.criterion)")
            return false
        }
    }
}
