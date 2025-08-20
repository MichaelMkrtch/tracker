//
//  AwardsView.swift
//  Tracker
//
//  Created by Michael on 8/19/25.
//

import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var dataController: DataController
    
    // The Award.example value will not be used. It is just meant
    // to prevent an optional type for selectedAward
    @State private var selectedAward = Award.example
    @State private var showingAwardDetails = false
    
    var awardTitle: String {
        if dataController.hasEarned(award: selectedAward) {
            return "Unlocked: \(selectedAward.name)"
        } else {
            return "Locked"
        }
    }
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 100))]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(Award.allAwards) { award in
                        Button {
                            selectedAward = award
                            showingAwardDetails = true
                        } label: {
                            Image(systemName: award.image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 100, height: 100)
                                .foregroundColor(dataController.hasEarned(award: award)
                                                 ? Color(award.color)
                                                 : .secondary.opacity(0.5))
                        }
                        .accessibilityLabel(dataController.hasEarned(award: award) ? "Unlocked: \(award.name)" : "Locked")
                        .accessibilityHint(award.description)
                    }
                }
            }
            .navigationTitle("Awards")
        }
        .alert(awardTitle, isPresented: $showingAwardDetails) {
        } message: {
            Text(selectedAward.description)
        }
    }
}

#Preview {
    AwardsView()
}
