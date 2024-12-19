// Views/Matches/MatchListView.swift
import SwiftUI

struct MatchListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Match.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Match.date, ascending: false)]
    ) var matches: FetchedResults<Match>
    
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var sortOption = SortOption.date
    @State private var selectedCountry: String?
    @State private var selectedLeague: League?
    @State private var selectedClub: Club?
    
    enum SortOption: String, CaseIterable {
        case date = "日付順"
        case league = "リーグ順"
    }
    
    // 利用可能な国とリーグのリストを取得
    @FetchRequest(
        entity: League.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \League.name, ascending: true)]
    ) var availableLeagues: FetchedResults<League>
    
    var availableCountries: [String] {
        Array(Set(availableLeagues.compactMap { $0.country })).sorted()
    }
    
    var availableClubs: [Club] {
        if let selectedLeague = selectedLeague {
            return selectedLeague.wrappedClubs
        } else if let selectedCountry = selectedCountry {
            return Array(Set(availableLeagues.filter { $0.country == selectedCountry }
                .flatMap { $0.wrappedClubs }))
        }
        return Array(Set(availableLeagues.flatMap { $0.wrappedClubs }))
    }
    
    var filteredMatches: [Match] {
        var result = matches.filter { match in
            let matchesSearch = searchText.isEmpty ||
                (match.opponent?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (match.clubs?.name?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesCountry = selectedCountry == nil ||
                match.clubs?.leagues?.country == selectedCountry
            let matchesLeague = selectedLeague == nil ||
                match.clubs?.leagues == selectedLeague
            let matchesClub = selectedClub == nil ||
                match.clubs == selectedClub
            
            return matchesSearch && matchesCountry && matchesLeague && matchesClub
        }
        
        result.sort { first, second in
            switch sortOption {
            case .date:
                return first.date > second.date
            case .league:
                let firstLeague = first.clubs?.leagues?.wrappedName ?? ""
                let secondLeague = second.clubs?.leagues?.wrappedName ?? ""
                if firstLeague == secondLeague {
                    return first.date > second.date
                }
                return firstLeague < secondLeague
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            Section {
                SearchField(text: $searchText, placeholder: "試合を検索...")
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
                                selectedLeague = nil
                                selectedClub = nil
                            }
                            ForEach(availableCountries, id: \.self) { country in
                                Button(country) {
                                    selectedCountry = country
                                    selectedLeague = nil
                                    selectedClub = nil
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
                                selectedClub = nil
                            }
                            ForEach(availableLeagues.filter {
                                selectedCountry == nil || $0.country == selectedCountry
                            }) { league in
                                Button(league.wrappedName) {
                                    selectedLeague = league
                                    selectedClub = nil
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
                        
                        // クラブ選択
                        Menu {
                            Button("全て") {
                                selectedClub = nil
                            }
                            ForEach(availableClubs) { club in
                                Button(club.wrappedName) {
                                    selectedClub = club
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedClub?.wrappedName ?? "クラブを選択")
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
            
            ForEach(filteredMatches) { match in
                NavigationLink(destination: MatchDetailView(match: match)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(match.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(match.resultDisplay)
                                .foregroundColor(
                                    match.homeScore > match.awayScore ?
                                        (match.isHome ? .green : .red) :
                                        match.homeScore < match.awayScore ?
                                            (match.isHome ? .red : .green) : .primary
                                )
                        }
                        HStack {
                            if match.isHome {
                                if let club = match.clubs {
                                    Text(club.wrappedName)
                                }
                                Text("vs")
                                Text(match.wrappedOpponent)
                            } else {
                                Text(match.wrappedOpponent)
                                Text("vs")
                                if let club = match.clubs {
                                    Text(club.wrappedName)
                                }
                            }
                            Spacer()
                            Text("\(match.homeScore) - \(match.awayScore)")
                                .font(.headline)
                        }
                    }
                }
            }
            .onDelete(perform: deleteMatches)
        }
        .navigationTitle("試合一覧")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddMatchView()) {
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
    
    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            offsets.map { matches[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                alertMessage = "削除に失敗しました"
                showingAlert = true
            }
        }
    }
}
