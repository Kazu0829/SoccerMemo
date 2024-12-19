// Models/ValidationError.swift
import Foundation

enum ValidationError: LocalizedError {
    // 既存のケース
    case emptyName
    case invalidDate
    case invalidScore
    case invalidHeight
    
    // 新規追加のケース
    case invalidLeagueName
    case invalidClubName
    case invalidPosition
    case invalidSeason
    case invalidCountry
    case invalidOpponent
    case invalidMatchDate
    case clubNotSelected
    case leagueNotSelected
    case duplicateEntry
    
    var errorDescription: String? {
        switch self {
        // 既存のエラーメッセージ
        case .emptyName:
            return "名前を入力してください"
        case .invalidDate:
            return "無効な日付です"
        case .invalidScore:
            return "スコアは0以上の数字を入力してください"
        case .invalidHeight:
            return "身長は140cm以上220cm以下で入力してください"
            
        // 新規追加のエラーメッセージ
        case .invalidLeagueName:
            return "有効なリーグ名を入力してください"
        case .invalidClubName:
            return "有効なクラブ名を入力してください"
        case .invalidPosition:
            return "ポジションを選択してください"
        case .invalidSeason:
            return "シーズンを入力してください"
        case .invalidCountry:
            return "国名を入力してください"
        case .invalidOpponent:
            return "対戦相手を入力してください"
        case .invalidMatchDate:
            return "試合日を選択してください"
        case .clubNotSelected:
            return "クラブを選択してください"
        case .leagueNotSelected:
            return "リーグを選択してください"
        case .duplicateEntry:
            return "既に登録されています"
        }
    }
}
