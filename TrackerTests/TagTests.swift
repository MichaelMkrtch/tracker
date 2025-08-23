//
//  TagTests.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import CoreData
import Testing
@testable import Tracker

@Suite
struct TagTests: UsesCoreDataFixture {
var fixture: CoreDataFixture

    init() {
        // fresh fixture per suite instance
        fixture = CoreDataFixture()
    }

    @Test func creatingTagsAndIssues() {
        let count = 10

        for _ in 0..<count {
            let tag = Tag(context: context)

            for _ in 0..<count {
                let issue = Issue(context: context)
                tag.addToIssues(issue)
            }
        }

        #expect(
            dataController.count(for: Tag.fetchRequest()) == count,
            "Expected\(count) tags."
        )
        #expect(dataController.count(
            for: Issue.fetchRequest()) == count * count,
            "Expected \(count * count) issues."
        )
    }

    @Test func deletingTagDoesNotDeleteIssues() throws {
        dataController.createSampleData()

        let request = NSFetchRequest<Tracker.Tag>(entityName: "Tag")
        let tags = try context.fetch(request)

        dataController.delete(tags[0])

        #expect(
            dataController.count(for: Tag.fetchRequest()) == 4,
            "Expected 4 tags after deleting 1."
        )
        #expect(
            dataController.count(for: Issue.fetchRequest()) == 50,
            "Expected 50 issues after deleting a tag."
        )
    }

}

