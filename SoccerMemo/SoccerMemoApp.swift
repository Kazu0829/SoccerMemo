
// SoccerMemoApp.swift
import SwiftUI

@main
struct SoccerMemoApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, dataController.viewContext)
        }
    }
}
