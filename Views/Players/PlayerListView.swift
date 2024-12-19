// Views/Players/PlayerListView.swift
import SwiftUI

struct PlayerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Player.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Player.name, ascending: true)]
    ) var players: FetchedResults<Player>
    
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var sortOption = SortOption.name
    @State private var selectedCountry: String?
    @State private var selectedLeague: League?
    @State private var selectedClub: Club?
    @State private var selectedPosition: String?
    
    enum SortOption: String, CaseIterable {
        case name = "名前順"
        case position = "ポジション順"
        case age = "年齢順"
    }
    
    let positions = ["GK", "DF", "MF", "FW"]
    
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
    
    var filteredPlayers: [Player] {
        var result = players.filter { player in
            let matchesSearch = searchText.isEmpty ||
                (player.name?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesCountry = selectedCountry == nil ||
                player.clubs?.leagues?.country == selectedCountry
            let matchesLeague = selectedLeague == nil ||
                player.clubs?.leagues == selectedLeague
            let matchesClub = selectedClub == nil ||
                player.clubs == selectedClub
            let matchesPosition = selectedPosition == nil ||
                player.position == selectedPosition
            
            return matchesSearch && matchesCountry && matchesLeague &&
                   matchesClub && matchesPosition
        }
        
        result.sort { first, second in
            switch sortOption {
            case .name:
                return first.wrappedName < second.wrappedName
            case .position:
                return first.wrappedPosition < second.wrappedPosition
            case .age:
                return first.birthDate > second.birthDate  // 若い順
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            Section {
                SearchField(text: $searchText, placeholder: "選手を検索...")
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
                        
                        // ポジション選択
                        Menu {
                            Button("全て") {
                                selectedPosition = nil
                            }
                            ForEach(positions, id: \.self) { position in
                                Button(position) {
                                    selectedPosition = position
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPosition ?? "ポジションを選択")
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
            
            ForEach(filteredPlayers) { player in
                NavigationLink(destination: PlayerDetailView(player: player)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.wrappedName)
                            .font(.headline)
                        HStack {
                            Text(player.wrappedPosition)
                            Text("•")
                            Text("\(player.height)cm")
                            if let club = player.clubs {
                                Text("•")
                                Text(club.wrappedName)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deletePlayers)
        }
        .navigationTitle("選手一覧")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddPlayerView()) {
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
    
    private func deletePlayers(offsets: IndexSet) {
        withAnimation {
            offsets.map { players[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                alertMessage = "削除に失敗しました"
                showingAlert = true
            }
        }
    }
}
