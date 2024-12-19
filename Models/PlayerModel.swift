// Models/PlayerModel.swift
import Foundation
import CoreData

@objc(Player)
public class Player: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var position: String?
    @NSManaged public var birthDate: Date
    @NSManaged public var height: Int16
    @NSManaged public var clubs: Club?
    @NSManaged public var matches: NSSet?
    
    public var wrappedName: String {
        name ?? "Unknown"
    }
    
    public var wrappedPosition: String {
        position ?? "Unknown"
    }
    
    public var wrappedClubName: String {
        clubs?.wrappedName ?? "所属クラブなし"
    }
    
    public var wrappedMatches: [Match] {
        let set = matches as? Set<Match> ?? []
        return Array(set).sorted { $0.date > $1.date }
    }
}

extension Player: Identifiable {
    static var example: Player {
        let player = Player(context: DataController.shared.viewContext)
        player.id = UUID()
        player.name = "サンプル選手"
        player.position = "FW"
        player.birthDate = Date()
        player.height = 175
        return player
    }
}
