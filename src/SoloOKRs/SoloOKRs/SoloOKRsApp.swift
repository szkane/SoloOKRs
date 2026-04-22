// SoloOKRsApp.swift
// SoloOKRs
//
// Created by Kane on 2/4/26.

import SwiftUI
import SwiftData

@main
struct SoloOKRsApp: App {
    @AppStorage("preferredLanguage") private var preferredLanguage = ""
    @AppStorage("appTheme") private var appTheme = "system"
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Objective.self,
            KeyResult.self,
            OKRTask.self,
            OKRReview.self,
            KRReviewEntry.self
        ])

        #if targetEnvironment(simulator)
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .automatic
        #endif

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let primaryError = error as NSError

            // If primary store fails to load, recover with a local, non-CloudKit fallback store.
            let fallbackURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("SoloOKRs-fallback.store")
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                url: fallbackURL,
                cloudKitDatabase: .none
            )

            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                let fallbackError = error as NSError
                fatalError(
                    "Could not create ModelContainer: primary=\(primaryError) | primaryDomain=\(primaryError.domain) primaryCode=\(primaryError.code) primaryUserInfo=\(primaryError.userInfo) | fallback=\(fallbackError) | fallbackDomain=\(fallbackError.domain) fallbackCode=\(fallbackError.code) fallbackUserInfo=\(fallbackError.userInfo)"
                )
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
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
        Window(Text(verbatim: localizedTitle("Edit Task")), id: "editTask") {
            EditTaskWindowView()
                .preferredColorScheme(colorScheme)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
        
        // Add Task Window - resizable and movable
        Window(Text(verbatim: localizedTitle("New Task")), id: "addTask") {
            AddTaskWindowView()
                .preferredColorScheme(colorScheme)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
                .environment(\.locale, preferredLanguage.isEmpty ? .current : Locale(identifier: preferredLanguage))
                .id(preferredLanguage)
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
    
    /// Resolves a localization key using the app's preferred language bundle.
    private func localizedTitle(_ key: String) -> String {
        let lang = preferredLanguage.isEmpty ? Locale.current.identifier : preferredLanguage
        for code in [lang, String(lang.prefix(2))] {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let result = bundle.localizedString(forKey: key, value: nil, table: nil)
                if result != key { return result }
            }
        }
        return key
    }
}
