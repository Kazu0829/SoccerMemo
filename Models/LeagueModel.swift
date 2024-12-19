// Models/LeagueModel.swift
import Foundation
import CoreData

@objc(League)
public class League: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var country: String?
    @NSManaged public var season: String?
    @NSManaged public var clubs: NSSet?
    
    public var wrappedName: String {
        name ?? "Unknown League"
    }
    
    public var wrappedCountry: String {
        country ?? "Unknown Country"
    }
    
    public var wrappedSeason: String {
        season ?? "Unknown Season"
    }
    
    public var wrappedClubs: [Club] {
        let set = clubs as? Set<Club> ?? []
        return Array(set).sorted { $0.wrappedName < $1.wrappedName }
    }
}

extension League: Identifiable {
    static var example: League {
        let league = League(context: DataController.shared.viewContext)
        league.id = UUID()
        league.name = "サンプルリーグ"
        league.country = "日本"
        league.season = "2023-2024"
        return league
    }
}
