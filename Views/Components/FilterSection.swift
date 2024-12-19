// Views/Components/FilterSection.swift
import SwiftUI

struct FilterSection<T: Hashable>: View {
    let title: String
    let options: [(value: T?, label: String)]
    @Binding var selection: T?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label)
                        .tag(option.value)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 4)
    }
}
