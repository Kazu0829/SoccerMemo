// Views/Players/AddPlayerView.swift
import SwiftUI

struct AddPlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var player: Player?
    
    @FetchRequest(
        entity: Club.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Club.name, ascending: true)]
    ) private var clubs: FetchedResults<Club>
    
    @State private var name = ""
    @State private var position = "FW"
    @State private var selectedYear = Calendar.current.component(.year, from: Date()) - 29  // 1995年を初期値に
    @State private var selectedMonth = 1
    @State private var selectedDay = 1
    @State private var height: Int16 = 175  // 身長の初期値を175cmに
    @State private var selectedClub: Club?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    let positions = ["GK", "DF", "MF", "FW"]
    let years = Array(1970...Calendar.current.component(.year, from: Date())).reversed()
    let months = Array(1...12)
    
    var days: [Int] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        let date = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return Array(range)
    }
    
    var birthDate: Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        return Calendar.current.date(from: components) ?? Date()
    }
    
    init(player: Player? = nil) {
        self.player = player
        if let player = player {
            _name = State(initialValue: player.name ?? "")
            _position = State(initialValue: player.position ?? "FW")
            _height = State(initialValue: player.height)
            _selectedClub = State(initialValue: player.clubs)
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: player.birthDate)
            _selectedYear = State(initialValue: components.year ?? Calendar.current.component(.year, from: Date()) - 29)
            _selectedMonth = State(initialValue: components.month ?? 1)
            _selectedDay = State(initialValue: components.day ?? 1)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("名前", text: $name)
                Picker("ポジション", selection: $position) {
                    ForEach(positions, id: \.self) { position in
                        Text(position).tag(position)
                    }
                }
            }
            
            Section(header: Text("生年月日")) {
                Grid(alignment: .leading, horizontalSpacing: 8) {
                    GridRow {
                        Menu {
                            Picker("", selection: $selectedYear) {
                                ForEach(years, id: \.self) { year in
                                    Text("\(year)").tag(year)
                                }
                            }
                        } label: {
                            Text("\(selectedYear)")
                                .frame(width: 60, alignment: .trailing)
                        }
                        Text("年")
                        
                        Menu {
                            Picker("", selection: $selectedMonth) {
                                ForEach(months, id: \.self) { month in
                                    Text(String(format: "%02d", month)).tag(month)
                                }
                            }
                        } label: {
                            Text(String(format: "%02d", selectedMonth))
                                .frame(width: 40, alignment: .trailing)
                        }
                        Text("月")
                        
                        Menu {
                            Picker("", selection: $selectedDay) {
                                ForEach(days, id: \.self) { day in
                                    Text(String(format: "%02d", day)).tag(day)
                                }
                            }
                        } label: {
                            Text(String(format: "%02d", selectedDay))
                                .frame(width: 40, alignment: .trailing)
                        }
                        Text("日")
                    }
                }
            }
            
            Section {
                Stepper("身長: \(height)cm", value: $height, in: 140...220)
            }
            
            Section(header: Text("所属クラブ")) {
                Picker("クラブ", selection: $selectedClub) {
                    Text("所属なし").tag(nil as Club?)
                    ForEach(clubs) { club in
                        Text(club.wrappedName).tag(club as Club?)
                    }
                }
            }
        }
        .navigationTitle(player == nil ? "選手追加" : "選手編集")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    savePlayer()
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
    
    private func savePlayer() {
        guard !name.isEmpty else {
            errorMessage = "名前を入力してください"
            showingErrorAlert = true
            return
        }
        
        let playerToSave = player ?? Player(context: viewContext)
        
        playerToSave.id = playerToSave.id ?? UUID()
        playerToSave.name = name
        playerToSave.position = position
        playerToSave.birthDate = birthDate
        playerToSave.height = height
        playerToSave.clubs = selectedClub
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました"
            showingErrorAlert = true
        }
    }
}
