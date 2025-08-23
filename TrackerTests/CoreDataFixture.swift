//
//  CoreDataFixture.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import CoreData
@testable import Tracker

struct CoreDataFixture {
    let dataController: DataController
    let context: NSManagedObjectContext

    init() {
        dataController = DataController(inMemory: true)
        context = dataController.container.viewContext
    }
}
