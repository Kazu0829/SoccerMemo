// Views/Leagues/LeagueListView.swift
import SwiftUI

struct LeagueListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: League.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \League.name, ascending: true)]
    ) var leagues: FetchedResults<League>
    
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var sortOption = SortOption.name
    @State private var selectedCountry: String?
    @State private var selectedSeason: String?
    
    enum SortOption: String, CaseIterable {
        case name = "名前順"
        case country = "国順"
    }
    
    // 利用可能な国とシーズンのリストを取得
    var availableCountries: [String] {
        Array(Set(leagues.compactMap { $0.country })).sorted()
    }
    
    var availableSeasons: [String] {
        Array(Set(leagues.compactMap { $0.season })).sorted().reversed()
    }
    
    var filteredLeagues: [League] {
        var result = leagues.filter { league in
            let matchesSearch = searchText.isEmpty ||
                (league.name?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesCountry = selectedCountry == nil || league.country == selectedCountry
            let matchesSeason = selectedSeason == nil || league.season == selectedSeason
            
            return matchesSearch && matchesCountry && matchesSeason
        }
        
        result.sort { first, second in
            switch sortOption {
            case .name:
                return first.wrappedName < second.wrappedName
            case .country:
                return first.wrappedCountry < second.wrappedCountry
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            Section {
                SearchField(text: $searchText, placeholder: "リーグを検索...")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                
                VStack(alignment: .leading, spacing: 12) {
                    // 並び替え
                    VStack(alignment: .leading) {
                        Text("並び替え")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // フィルター
                    VStack(alignment: .leading, spacing: 8) {
                        Text("フィルター")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 国選択
                        Menu {
                            Button("全て") {
                                selectedCountry = nil
                            }
                            ForEach(availableCountries, id: \.self) { country in
                                Button(country) {
                                    selectedCountry = country
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCountry ?? "国を選択")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // シーズン選択
                        Menu {
                            Button("全て") {
                                selectedSeason = nil
                            }
                            ForEach(availableSeasons, id: \.self) { season in
                                Button(season) {
                                    selectedSeason = season
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedSeason ?? "シーズンを選択")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            ForEach(filteredLeagues) { league in
                NavigationLink(destination: LeagueDetailView(league: league)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(league.wrappedName)
                            .font(.headline)
                        HStack {
                            Text(league.wrappedCountry)
                            Text("•")
                            Text(league.wrappedSeason)
                            if !league.wrappedClubs.isEmpty {
                                Text("•")
                                Text("\(league.wrappedClubs.count)クラブ")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteLeagues)
        }
        .navigationTitle("リーグ一覧")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddLeagueView()) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteLeagues(offsets: IndexSet) {
        withAnimation {
            offsets.map { leagues[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                alertMessage = "削除に失敗しました"
                showingAlert = true
            }
        }
    }
}
