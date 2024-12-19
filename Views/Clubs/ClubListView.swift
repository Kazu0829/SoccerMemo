// Views/Clubs/ClubListView.swift
import SwiftUI

struct ClubListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Club.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Club.name, ascending: true)]
    ) var clubs: FetchedResults<Club>
    
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var mainSortOption = MainSortOption.name
    @State private var statsSortOption = StatsSortOption.points
    @State private var selectedCountry: String?
    @State private var selectedLeague: League?
    
    // 並び替え1（基本情報）
    enum MainSortOption: String, CaseIterable {
        case name = "名前順"
        case league = "リーグ順"
        case country = "国順"
    }
    
    // 並び替え2（成績）
    enum StatsSortOption: String, CaseIterable {
        case points = "勝点順"
        case wins = "勝ち順"
        case losses = "負け順"
        case goalsFor = "得点順"
        case goalsAgainst = "失点順"
    }
    
    // 利用可能な国とリーグのリストを取得
    @FetchRequest(
        entity: League.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \League.name, ascending: true)]
    ) var availableLeagues: FetchedResults<League>
    
    var availableCountries: [String] {
        Array(Set(availableLeagues.compactMap { $0.country })).sorted()
    }
    
    var filteredClubs: [Club] {
        var result = clubs.filter { club in
            let matchesSearch = searchText.isEmpty ||
                (club.name?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesCountry = selectedCountry == nil ||
                club.leagues?.country == selectedCountry
            let matchesLeague = selectedLeague == nil ||
                club.leagues == selectedLeague
            
            return matchesSearch && matchesCountry && matchesLeague
        }
        
        // メインソート適用
        result.sort { first, second in
            switch mainSortOption {
            case .name:
                return first.wrappedName < second.wrappedName
            case .league:
                return (first.leagues?.wrappedName ?? "") < (second.leagues?.wrappedName ?? "")
            case .country:
                return (first.leagues?.wrappedCountry ?? "") < (second.leagues?.wrappedCountry ?? "")
            }
        }
        
        // スタッツソート適用（メインソートの順序を保持しつつ）
        result.sort { first, second in
            let firstStats = calculateStats(for: first)
            let secondStats = calculateStats(for: second)
            
            switch statsSortOption {
            case .points:
                return firstStats.points > secondStats.points
            case .wins:
                return firstStats.wins > secondStats.wins
            case .losses:
                return firstStats.losses > secondStats.losses
            case .goalsFor:
                return firstStats.goalsFor > secondStats.goalsFor
            case .goalsAgainst:
                return firstStats.goalsAgainst > secondStats.goalsAgainst
            }
        }
        
        return result
    }
    
    struct ClubStats {
        let points: Int
        let wins: Int
        let losses: Int
        let goalsFor: Int
        let goalsAgainst: Int
    }
    
    func calculateStats(for club: Club) -> ClubStats {
        var wins = 0, losses = 0, draws = 0
        var goalsFor = 0, goalsAgainst = 0
        
        for match in club.wrappedMatches {
            if match.isHome {
                goalsFor += Int(match.homeScore)
                goalsAgainst += Int(match.awayScore)
                if match.homeScore > match.awayScore {
                    wins += 1
                } else if match.homeScore < match.awayScore {
                    losses += 1
                } else {
                    draws += 1
                }
            } else {
                goalsFor += Int(match.awayScore)
                goalsAgainst += Int(match.homeScore)
                if match.awayScore > match.homeScore {
                    wins += 1
                } else if match.awayScore < match.homeScore {
                    losses += 1
                } else {
                    draws += 1
                }
            }
        }
        
        return ClubStats(
            points: wins * 3 + draws,
            wins: wins,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst
        )
    }
    
    var body: some View {
        List {
            Section {
                SearchField(text: $searchText, placeholder: "クラブを検索...")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                
                VStack(alignment: .leading, spacing: 12) {
                    // 並び替え1
                    VStack(alignment: .leading) {
                        Text("並び替え（基本）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $mainSortOption) {
                            ForEach(MainSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // 並び替え2
                    VStack(alignment: .leading) {
                        Text("並び替え（成績）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("", selection: $statsSortOption) {
                            ForEach(StatsSortOption.allCases, id: \.self) { option in
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
                                    selectedLeague = nil  // 国が変更されたらリーグをリセット
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
                        
                        // リーグ選択
                        Menu {
                            Button("全て") {
                                selectedLeague = nil
                            }
                            ForEach(availableLeagues.filter { selectedCountry == nil || $0.country == selectedCountry }) { league in
                                Button(league.wrappedName) {
                                    selectedLeague = league
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedLeague?.wrappedName ?? "リーグを選択")
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
            
            ForEach(filteredClubs) { club in
                NavigationLink(destination: ClubDetailView(club: club)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(club.wrappedName)
                            .font(.headline)
                        HStack {
                            if let league = club.leagues {
                                Text(league.wrappedName)
                            }
                            Text("•")
                            let stats = calculateStats(for: club)
                            Text("\(stats.points)pt")
                            Text("•")
                            Text("\(stats.wins)勝\(club.wrappedMatches.count - stats.wins - stats.losses)分\(stats.losses)敗")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteClubs)
        }
        .navigationTitle("クラブ一覧")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddClubView()) {
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
    
    private func deleteClubs(offsets: IndexSet) {
        withAnimation {
            offsets.map { clubs[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                alertMessage = "削除に失敗しました"
                showingAlert = true
            }
        }
    }
}
