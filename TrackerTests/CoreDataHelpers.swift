//
//  CoreDataHelpers.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import CoreData
@testable import Tracker

protocol UsesCoreDataFixture {
    var fixture: CoreDataFixture { get }
}

extension UsesCoreDataFixture {
    var context: NSManagedObjectContext { fixture.context }
    var dataController: DataController { fixture.dataController }
}
