//
//  TrackerApp.swift
//  Tracker
//
//  Created by Michael on 8/2/25.
//

import SwiftUI

@main
struct TrackerApp: App {
    // App will create and own this. It will stay alive for the duration of the app.
    @StateObject var dataController = DataController()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
            } content: {
                ContentView()
            } detail: {
                DetailView()
            }
                // Allows access to data controller throughout app
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase != .active {
                        dataController.save()
                    }
                }
        }
    }
}
