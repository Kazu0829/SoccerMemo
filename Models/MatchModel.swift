// Models/MatchModel.swift
import Foundation
import CoreData

@objc(Match)
public class Match: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date
    @NSManaged public var opponent: String?
    @NSManaged public var isHome: Bool
    @NSManaged public var homeScore: Int16
    @NSManaged public var awayScore: Int16
    @NSManaged public var clubs: Club?
    @NSManaged public var players: NSSet?
    
    public var wrappedOpponent: String {
        opponent ?? "Unknown"
    }
    
    public var wrappedClubName: String {
        clubs?.wrappedName ?? "Unknown Club"
    }
    
    public var wrappedPlayers: [Player] {
        let set = players as? Set<Player> ?? []
        return Array(set).sorted { $0.wrappedName < $1.wrappedName }
    }
    
    public var resultDisplay: String {
        if homeScore > awayScore {
            return isHome ? "Win" : "Loss"
        } else if homeScore < awayScore {
            return isHome ? "Loss" : "Win"
        } else {
            return "Draw"
        }
    }
}

extension Match: Identifiable {
    static var example: Match {
        let match = Match(context: DataController.shared.viewContext)
        match.id = UUID()
        match.date = Date()
        match.opponent = "サンプルチーム"
        match.isHome = true
        match.homeScore = 2
        match.awayScore = 1
        return match
    }
}
