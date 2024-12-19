// Views/Leagues/LeagueDetailView.swift
import SwiftUI

struct LeagueDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let league: League
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // 順位表のデータを計算
    var standings: [(club: Club, points: Int, wins: Int, draws: Int, losses: Int, goalsFor: Int, goalsAgainst: Int)] {
        league.wrappedClubs.map { club in
            var wins = 0, draws = 0, losses = 0
            var goalsFor = 0, goalsAgainst = 0
            
            for match in club.wrappedMatches {
                if match.isHome {
                    goalsFor += Int(match.homeScore)
                    goalsAgainst += Int(match.awayScore)
                    if match.homeScore > match.awayScore { wins += 1 }
                    else if match.homeScore == match.awayScore { draws += 1 }
                    else { losses += 1 }
                } else {
                    goalsFor += Int(match.awayScore)
                    goalsAgainst += Int(match.homeScore)
                    if match.awayScore > match.homeScore { wins += 1 }
                    else if match.awayScore == match.homeScore { draws += 1 }
                    else { losses += 1 }
                }
            }
            
            let points = (wins * 3) + draws
            
            return (club, points, wins, draws, losses, goalsFor, goalsAgainst)
        }.sorted { $0.points > $1.points }
    }
    
    var body: some View {
        List {
            Section(header: Text("リーグ情報")) {
                DetailRow(title: "リーグ名", value: league.wrappedName)
                DetailRow(title: "国", value: league.wrappedCountry)
                DetailRow(title: "シーズン", value: league.wrappedSeason)
                DetailRow(title: "クラブ数", value: "\(league.wrappedClubs.count)クラブ")
            }
            
            if !standings.isEmpty {
                Section(header: Text("順位表")) {
                    ForEach(standings, id: \.club.id) { standing in
                        NavigationLink(destination: ClubDetailView(club: standing.club)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(standing.club.wrappedName)
                                    .font(.headline)
                                HStack {
                                    Text("\(standing.points)pts")
                                        .foregroundColor(.primary)
                                    Text("•")
                                    Text("\(standing.wins)-\(standing.draws)-\(standing.losses)")
                                    Text("•")
                                    Text("得失点: \(standing.goalsFor)-\(standing.goalsAgainst)")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(league.wrappedName)
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
                AddLeagueView(league: league)
            }
        }
        .alert("リーグの削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteLeague()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(league.wrappedName)を削除しますか？")
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteLeague() {
        viewContext.delete(league)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "削除に失敗しました"
            showingErrorAlert = true
        }
    }
}
