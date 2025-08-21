//
//  IssueView.swift
//  Tracker
//
//  Created by Michael on 8/17/25.
//

import SwiftUI

struct IssueView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    TextField(
                        "Title",
                        text: $issue.issueTitle,
                        prompt: Text("Enter the issue title here")
                    )
                    .font(.title)

                    Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)

                    Text("**Status:** \(issue.issueStatus)")
                        .foregroundStyle(.secondary)
                }

                Picker("Priority", selection: $issue.priority) {
                    // CoreData uses Int16 for the issue priority
                    // issue.priority isn't wrapped with a helper because it can expose us to
                    // subtle runtime bugs that the compiler won't catch due to tag accepting generics
                    Text("Low").tag(Int16(0))
                    Text("Medium").tag(Int16(1))
                    Text("High").tag(Int16(2))
                }

                TagsMenuView(issue: issue)
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Basic Information")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Description",
                        text: $issue.issueContent,
                        prompt: Text("Enter the issue description here"),
                        axis: .vertical
                    )
                }
            }
        }
        .disabled(issue.isDeleted)
        .onReceive(issue.objectWillChange) { _ in
            dataController.queueSave()
        }
        // Performs an immediate write when a text field is submitted.
        // This is another step meant to ensure user data is never lost.
        .onSubmit(dataController.save)
        .toolbar {
            IssueViewToolbar(issue: issue)
        }
    }
}

#Preview {
    IssueView(issue: .example)
}
