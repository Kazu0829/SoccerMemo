// Views/Clubs/ClubDetailView.swift
import SwiftUI
import CoreData

struct ClubDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let club: Club
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // 試合統計を計算
    private var stats: ClubStats {
        let matches = club.wrappedMatches
        
        var wins = 0
        var draws = 0
        var losses = 0
        var goalsFor = 0
        var goalsAgainst = 0
        
        for match in matches {
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
            wins: wins,
            draws: draws,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst
        )
    }
    
    var body: some View {
        List {
            Section(header: Text("基本情報")) {
                DetailRow(title: "クラブ名", value: club.wrappedName)
                DetailRow(title: "所属選手数", value: "\(club.wrappedPlayers.count)名")
                DetailRow(title: "試合数", value: "\(club.wrappedMatches.count)試合")
            }
            
            Section(header: Text("成績")) {
                DetailRow(title: "試合数", value: "\(stats.gamesPlayed)試合")
                DetailRow(title: "勝敗", value: "\(stats.wins)勝 \(stats.draws)分 \(stats.losses)敗")
                DetailRow(title: "勝率", value: String(format: "%.1f%%", stats.winRate))
                DetailRow(title: "得点", value: "\(stats.goalsFor)点")
                DetailRow(title: "失点", value: "\(stats.goalsAgainst)点")
                DetailRow(title: "得失点差", value: "\(stats.goalDifference)点")
            }
            
            if !club.wrappedPlayers.isEmpty {
                Section(header: Text("所属選手")) {
                    ForEach(club.wrappedPlayers) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            VStack(alignment: .leading) {
                                Text(player.wrappedName)
                                    .font(.headline)
                                Text(player.wrappedPosition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            if !club.wrappedMatches.isEmpty {
                Section(header: Text("試合記録")) {
                    ForEach(club.wrappedMatches.sorted { $0.date > $1.date }) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            HStack {
                                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("vs \(match.wrappedOpponent)")
                                    .foregroundColor(.secondary)
                                Text(match.resultDisplay)
                                    .foregroundColor(
                                        match.resultDisplay == "Win" ? .green :
                                            match.resultDisplay == "Loss" ? .red : .primary
                                    )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(club.wrappedName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                AddClubView(club: club)
            }
        }
        .alert("クラブの削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteClub()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(club.wrappedName)を削除しますか？")
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteClub() {
        viewContext.delete(club)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "削除に失敗しました"
            showingErrorAlert = true
        }
    }
}

// クラブ統計情報を管理する構造体
struct ClubStats {
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    
    var gamesPlayed: Int { wins + draws + losses }
    var winRate: Double { gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) * 100 : 0 }
    var goalDifference: Int { goalsFor - goalsAgainst }
}

struct ClubDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClubDetailView(club: Club.example)
        }
        .environment(\.managedObjectContext, DataController.shared.viewContext)
    }
}
