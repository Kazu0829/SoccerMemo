// Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                LeagueListView()
            }
            .tabItem {
                Label("リーグ", systemImage: "trophy")
            }
            
            NavigationView {
                ClubListView()
            }
            .tabItem {
                Label("クラブ", systemImage: "building.2")
            }
            
            NavigationView {
                PlayerListView()
            }
            .tabItem {
                Label("選手", systemImage: "person.3")
            }
            
            NavigationView {
                MatchListView()
            }
            .tabItem {
                Label("試合", systemImage: "sportscourt")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, DataController.shared.viewContext)
    }
}
