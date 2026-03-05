// SoloOKRsApp.swift
// SoloOKRs
//
// Created by Kane on 2/4/26.

import SwiftUI
import SwiftData

@main
struct SoloOKRsApp: App {
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Objective.self,
            KeyResult.self,
            OKRTask.self,
            OKRReview.self,
            KRReviewEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enables CloudKit sync
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage) // Force redraw when language changes
                .onAppear {
                    MCPServer.shared.configure(modelContext: sharedModelContainer.mainContext)
                    
                    // Request notification permission for review reminders
                    Task {
                        await ReviewModeManager.shared.requestNotificationPermission()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        
        #if os(macOS)
        // Edit Task Window - resizable and movable
        Window("Edit Task", id: "editTask") {
            EditTaskWindowView()
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
        
        // Add Task Window - resizable and movable
        Window("New Task", id: "addTask") {
            AddTaskWindowView()
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        #endif
    }
}
