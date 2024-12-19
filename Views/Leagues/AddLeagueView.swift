// Views/Leagues/AddLeagueView.swift
import SwiftUI

struct AddLeagueView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var league: League?
    
    @State private var name = ""
    @State private var country = ""
    @State private var season = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedClubs = Set<Club>()
    
    // リーグに所属していないクラブを取得
    @FetchRequest(
        entity: Club.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Club.name, ascending: true)],
        predicate: NSPredicate(format: "leagues == nil")
    ) private var availableClubs: FetchedResults<Club>
    
    init(league: League? = nil) {
        self.league = league
        if let league = league {
            _name = State(initialValue: league.wrappedName)
            _country = State(initialValue: league.wrappedCountry)
            _season = State(initialValue: league.wrappedSeason)
            _selectedClubs = State(initialValue: Set(league.wrappedClubs))
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("リーグ情報")) {
                TextField("リーグ名", text: $name)
                TextField("国", text: $country)
                TextField("シーズン", text: $season)
            }
            
            Section(header: Text("所属クラブ")) {
                if let existingLeague = league {
                    ForEach(existingLeague.wrappedClubs) { club in
                        HStack {
                            Text(club.wrappedName)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(availableClubs) { club in
                    Toggle(isOn: Binding(
                        get: { selectedClubs.contains(club) },
                        set: { isSelected in
                            if isSelected {
                                selectedClubs.insert(club)
                            } else {
                                selectedClubs.remove(club)
                            }
                        }
                    )) {
                        Text(club.wrappedName)
                    }
                }
            }
            
            if league != nil {
                Section(header: Text("現在の所属クラブ")) {
                    ForEach(Array(selectedClubs), id: \.id) { club in
                        HStack {
                            Text(club.wrappedName)
                            Spacer()
                            Button {
                                selectedClubs.remove(club)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(league == nil ? "リーグ追加" : "リーグ編集")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveLeague()
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
    
    private func saveLeague() {
        guard !name.isEmpty else {
            errorMessage = "リーグ名を入力してください"
            showingErrorAlert = true
            return
        }
        
        let leagueToSave = league ?? League(context: viewContext)
        
        leagueToSave.id = leagueToSave.id ?? UUID()
        leagueToSave.name = name
        leagueToSave.country = country
        leagueToSave.season = season
        
        // 既存のクラブとの関連を解除
        if let existingLeague = league {
            existingLeague.wrappedClubs.forEach { club in
                club.leagues = nil
            }
        }
        
        // 新しい関連を設定
        selectedClubs.forEach { club in
            club.leagues = leagueToSave
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
