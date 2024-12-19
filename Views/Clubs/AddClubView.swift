// Views/Clubs/AddClubView.swift
import SwiftUI

struct AddClubView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 編集の場合は既存のClubを受け取る
    var club: Club?
    
    @State private var name = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // 編集時の初期値設定
    init(club: Club? = nil) {
        self.club = club
        _name = State(initialValue: club?.name ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("クラブ情報")) {
                TextField("クラブ名", text: $name)
            }
            
            if let existingClub = club, !existingClub.wrappedPlayers.isEmpty {
                Section(header: Text("所属選手")) {
                    ForEach(existingClub.wrappedPlayers) { player in
                        Text(player.wrappedName)
                    }
                }
            }
        }
        .navigationTitle(club == nil ? "クラブ追加" : "クラブ編集")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveClub()
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
    
    private func saveClub() {
        guard !name.isEmpty else {
            errorMessage = "クラブ名を入力してください"
            showingErrorAlert = true
            return
        }
        
        let clubToSave = club ?? Club(context: viewContext)
        
        clubToSave.id = clubToSave.id ?? UUID()
        clubToSave.name = name
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました"
            showingErrorAlert = true
        }
    }
}

struct AddClubView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddClubView()
        }
        .environment(\.managedObjectContext, DataController.shared.viewContext)
    }
}
