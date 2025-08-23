//
//  AwardsTests.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import CoreData
import Testing
@testable import Tracker

@Suite
struct AwardsTest: UsesCoreDataFixture {
    var fixture: CoreDataFixture
    let awards = Award.allAwards

    init() {
        // fresh fixture per suite instance
        fixture = CoreDataFixture()
    }

    @Test func awardIDMatchesName() {
        for award in awards {
            #expect(award.id == award.name, "Award ID should always match its name.")
        }
    }

    @Test func newUserHasUnlockedNoAwards() {
        for award in awards {
            #expect(dataController.hasEarned(award: award) == false, "New users should have no earned awards")
        }
    }

    @Test func closingIssuesUnlocksAwards() throws {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]

        for (count, value) in values.enumerated() {
            var issues = [Tracker.Issue]()

            try context.performAndWait {
                for _ in 0..<value {
                    let issue = Tracker.Issue(context: context)
                    issue.completed = true
                    issues.append(issue)
                }

                try context.save()
            }

            let matches = awards.filter { award in
                award.criterion == "closed" && dataController.hasEarned(award: award)
            }

            #expect(matches.count == count + 1, "Completing \(value) issues should unlock \(count + 1) awards")

            dataController.deleteAll()
        }
    }

    @Test func creatingIssuesUnlocksAwards() throws {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]

        for (count, value) in values.enumerated() {
            var issues = [Tracker.Issue]()

            try context.performAndWait {
                for _ in 0..<value {
                    let issue = Tracker.Issue(context: context)
                    issues.append(issue)
                }

                try context.save()
            }

            let matches = awards.filter { award in
                award.criterion == "issues" && dataController.hasEarned(award: award)
            }

            #expect(matches.count == count + 1, "Adding \(value) issues should unlock \(count + 1) awards")

            dataController.deleteAll()
        }
    }
}
