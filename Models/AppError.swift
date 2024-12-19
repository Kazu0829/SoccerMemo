// Models/AppError.swift
import Foundation

enum AppError: LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "データの保存に失敗しました"
        case .fetchFailed:
            return "データの取得に失敗しました"
        case .deleteFailed:
            return "データの削除に失敗しました"
        case .invalidData:
            return "無効なデータです"
        }
    }
}

