// Views/Players/PlayerDetailView.swift
import SwiftUI
import CoreData

struct PlayerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let player: Player
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section {
                DetailRow(title: "名前", value: player.wrappedName)
                DetailRow(title: "ポジション", value: player.wrappedPosition)
                DetailRow(title: "身長", value: "\(player.height)cm")
                DetailRow(title: "生年月日", value: player.birthDate.formatted(date: .abbreviated, time: .omitted))
                if let club = player.clubs {
                    NavigationLink(destination: ClubDetailView(club: club)) {
                        DetailRow(title: "所属クラブ", value: club.wrappedName)
                    }
                }
            } header: {
                Text("基本情報")
            }
            
            if !player.wrappedMatches.isEmpty {
                Section {
                    ForEach(player.wrappedMatches) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            HStack {
                                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("vs \(match.wrappedOpponent)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("試合記録")
                }
            }
        }
        .navigationTitle(player.wrappedName)
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
                AddPlayerView(player: player)
            }
        }
        .alert("選手の削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deletePlayer()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(player.wrappedName)を削除しますか？")
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deletePlayer() {
        // 関連する試合から選手を削除
        for match in player.wrappedMatches {
            if var players = match.players as? Set<Player> {
                players.remove(player)
                match.players = players as NSSet
            }
        }
        
        // 選手を削除
        viewContext.delete(player)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "削除に失敗しました"
            showingErrorAlert = true
        }
    }
}

struct PlayerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlayerDetailView(player: Player.example)
        }
        .environment(\.managedObjectContext, DataController.shared.viewContext)
    }
}
