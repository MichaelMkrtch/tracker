//
//  AssetTests.swift
//  TrackerTests
//
//  Created by Michael on 8/22/25.
//

import Testing
import UIKit
@testable import Tracker

struct AssetTests {
    @Test func testColorsExist() {
        let allColors = ["Dark Blue", "Dark Gray", "Gold", "Gray", "Green",
                         "Light Blue", "Midnight", "Orange", "Pink", "Purple", "Red", "Teal"]

        for color in allColors {
            #expect(UIColor(named: color) != nil, "Failed to load color '\(color)' from asset catalog.")
        }
    }

    @Test func testAwardsLoadCorrectly() {
        #expect(Award.allAwards.isEmpty == false, "Failed to load awards from JSON.")
    }
}
