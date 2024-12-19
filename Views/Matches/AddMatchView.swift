// Views/Matches/AddMatchView.swift
import SwiftUI
import CoreData

struct AddMatchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var match: Match?
    
    @State private var date = Date()
    @State private var opponent = ""
    @State private var isHome = true
    @State private var homeScore: Int16 = 0
    @State private var awayScore: Int16 = 0
    @State private var selectedClub: Club?
    @State private var selectedPlayers = Set<Player>()
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    @FetchRequest(
        entity: Club.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Club.name, ascending: true)]
    ) private var availableClubs: FetchedResults<Club>
    
    init(match: Match? = nil) {
        self.match = match
        _date = State(initialValue: match?.date ?? Date())
        _opponent = State(initialValue: match?.opponent ?? "")
        _isHome = State(initialValue: match?.isHome ?? true)
        _homeScore = State(initialValue: match?.homeScore ?? 0)
        _awayScore = State(initialValue: match?.awayScore ?? 0)
        _selectedClub = State(initialValue: match?.clubs)
        if let match = match {
            _selectedPlayers = State(initialValue: Set(match.wrappedPlayers))
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("クラブ選択")) {
                Picker("クラブ", selection: $selectedClub) {
                    Text("未選択").tag(nil as Club?)
                    ForEach(availableClubs) { club in
                        Text(club.wrappedName).tag(club as Club?)
                    }
                }
            }
            Section(header: Text("試合情報")) {
                DatePicker("試合日", selection: $date, displayedComponents: .date)
                TextField("対戦相手", text: $opponent)
                Toggle("ホームゲーム", isOn: $isHome)
            }
            
            Section(header: Text("スコア")) {
                Stepper("ホームスコア: \(homeScore)", value: $homeScore, in: 0...99)
                Stepper("アウェイスコア: \(awayScore)", value: $awayScore, in: 0...99)
            }
            
            if let club = selectedClub {
                Section(header: Text("出場選手選択")) {
                    ForEach(club.wrappedPlayers) { player in
                        Toggle(isOn: Binding(
                            get: { selectedPlayers.contains(player) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPlayers.insert(player)
                                } else {
                                    selectedPlayers.remove(player)
                                }
                            }
                        )) {
                            Text(player.wrappedName)
                        }
                    }
                }
            }
        }
        .navigationTitle(match == nil ? "試合追加" : "試合編集")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveMatch()
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addPlayerToMatch(_ player: Player, match: Match) {
        let players = match.players ?? NSSet()
        let mutable = players.mutableCopy() as! NSMutableSet
        mutable.add(player)
        match.players = mutable as NSSet
    }
    
    private func removePlayerFromMatch(_ player: Player, match: Match) {
        let players = match.players ?? NSSet()
        let mutable = players.mutableCopy() as! NSMutableSet
        mutable.remove(player)
        match.players = mutable as NSSet
    }
    
    private func saveMatch() {
        guard !opponent.isEmpty else {
            errorMessage = "対戦相手を入力してください"
            showingErrorAlert = true
            return
        }
        
        let matchToSave = match ?? Match(context: viewContext)
        matchToSave.id = matchToSave.id ?? UUID()
        matchToSave.date = date
        matchToSave.opponent = opponent
        matchToSave.isHome = isHome
        matchToSave.homeScore = homeScore
        matchToSave.awayScore = awayScore
        matchToSave.clubs = selectedClub
        
        // 出場選手の更新
        let currentPlayers = Set(matchToSave.wrappedPlayers)
        
        // 削除された選手を除去
        currentPlayers.subtracting(selectedPlayers).forEach { player in
            removePlayerFromMatch(player, match: matchToSave)
        }
        
        // 新しい選手を追加
        selectedPlayers.subtracting(currentPlayers).forEach { player in
            addPlayerToMatch(player, match: matchToSave)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました"
            showingErrorAlert = true
        }
    }
}
