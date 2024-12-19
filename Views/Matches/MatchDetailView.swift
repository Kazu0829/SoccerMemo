// Views/Matches/MatchDetailView.swift
import SwiftUI

struct MatchDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let match: Match
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var resultColor: Color {
        if match.homeScore > match.awayScore {
            return match.isHome ? .green : .red
        } else if match.homeScore < match.awayScore {
            return match.isHome ? .red : .green
        } else {
            return .primary
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("試合情報")) {
                DetailRow(title: "日付", value: match.date.formatted(date: .long, time: .omitted))
                if match.isHome {
                    if let club = match.clubs {
                        DetailRow(title: "ホーム", value: club.wrappedName)
                    }
                    DetailRow(title: "アウェイ", value: match.wrappedOpponent)
                } else {
                    DetailRow(title: "ホーム", value: match.wrappedOpponent)
                    if let club = match.clubs {
                        DetailRow(title: "アウェイ", value: club.wrappedName)
                    }
                }
                HStack {
                    Text("スコア")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(match.homeScore) - \(match.awayScore)")
                        .font(.headline)
                }
                HStack {
                    Text("結果")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(match.resultDisplay)
                        .foregroundColor(resultColor)
                        .font(.headline)
                }
            }
            
            if let club = match.clubs {
                Section(header: Text("クラブ情報")) {
                    NavigationLink(destination: ClubDetailView(club: club)) {
                        Text(club.wrappedName)
                    }
                }
            }
            
            if !match.wrappedPlayers.isEmpty {
                Section(header: Text("出場選手")) {
                    ForEach(match.wrappedPlayers) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            HStack {
                                Text(player.wrappedName)
                                Spacer()
                                Text(player.wrappedPosition)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("試合詳細")
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
                AddMatchView(match: match)
            }
        }
        .alert("試合の削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteMatch()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この試合記録を削除しますか？")
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteMatch() {
        viewContext.delete(match)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "削除に失敗しました"
            showingErrorAlert = true
        }
    }
}

struct MatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MatchDetailView(match: Match.example)
        }
        .environment(\.managedObjectContext, DataController.shared.viewContext)
    }
}
