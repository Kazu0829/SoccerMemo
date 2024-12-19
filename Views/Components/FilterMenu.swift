// Views/Components/FilterMenu.swift
import SwiftUI

struct FilterMenu<T: Hashable>: View {
    let title: String
    let options: [T]
    let optionToString: (T) -> String
    @Binding var selectedOption: T?
    
    var body: some View {
        Menu {
            Button("すべて") {
                selectedOption = nil
            }
            
            ForEach(options, id: \.self) { option in
                Button(optionToString(option)) {
                    selectedOption = option
                }
            }
        } label: {
            HStack {
                Text(title)
                Image(systemName: "chevron.down")
            }
        }
    }
}
