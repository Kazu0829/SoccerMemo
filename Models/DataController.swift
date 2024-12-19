// Models/DataController.swift
import CoreData
import SwiftUI

class DataController: ObservableObject {
    static let shared = DataController()
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init() {
        container = NSPersistentContainer(name: "SoccerMemo")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreDataの読み込みに失敗: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // 保存
    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("保存エラー: \(error)")
            }
        }
    }
    
    // 削除
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
    
    // バッチ削除
    func deleteBatch(_ objects: [NSManagedObject]) {
        objects.forEach { viewContext.delete($0) }
        save()
    }
}
