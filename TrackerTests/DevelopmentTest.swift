//
//  DevelopmentTest.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import CoreData
import Testing
@testable import Tracker

@Suite
struct DevelopmentTest: UsesCoreDataFixture {
    var fixture: CoreDataFixture

    init() {
        // fresh fixture per suite instance
        fixture = CoreDataFixture()
    }

    @Test func sampleDataCreationWorks() throws {
        dataController.createSampleData()

        try #require(dataController.count(for: Tag.fetchRequest()) == 5, "There should be 5 sample tags.")
        try #require(dataController.count(for: Issue.fetchRequest()) == 50, "There should be 50 sample issues.")
    }

    @Test func deleteAllClearsEverything() {
        dataController.createSampleData()
        dataController.deleteAll()

        #expect(dataController.count(for: Tag.fetchRequest()) == 0, "deleteAll() should leave 0 sample tags.")
        #expect(dataController.count(for: Issue.fetchRequest()) == 0, "deleteAll() should leave 0 sample issues.")
    }

    @Test func exampleTagHasNoIssues() {
        let tag = Tag.example
        #expect(tag.issues?.count == 0, "The 'example' tag should have 0 issues.")
    }

    @Test func exampleIssueIsHighPriority() {
        let issue = Issue.example
        #expect(issue.priority == 2, "The example issue should be high priority.")
    }
}
