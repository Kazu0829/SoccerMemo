// Models/ClubModel.swift
import Foundation
import CoreData

@objc(Club)
public class Club: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var players: NSSet?
    @NSManaged public var matches: NSSet?
    @NSManaged public var leagues: League?
    
    public var wrappedName: String {
        name ?? "Unknown"
    }
    
    public var wrappedLeagueName: String {
        leagues?.wrappedName ?? "所属リーグなし"
    }
    
    public var wrappedPlayers: [Player] {
        let set = players as? Set<Player> ?? []
        return Array(set).sorted { $0.wrappedName < $1.wrappedName }
    }
    
    public var wrappedMatches: [Match] {
        let set = matches as? Set<Match> ?? []
        return Array(set).sorted { $0.date > $1.date }
    }
}

extension Club: Identifiable {
    static var example: Club {
        let club = Club(context: DataController.shared.viewContext)
        club.id = UUID()
        club.name = "サンプルクラブ"
        return club
    }
}
