
import Foundation
import SwiftUI

// MARK: - Emotion Model
/// 사용자의 감정 상태를 정의하는 열거형 (5단계)
enum Emotion: String, Codable, CaseIterable, Identifiable {
    case veryGood = "매우 좋음"
    case good = "좋음"
    case neutral = "보통"
    case bad = "나쁨"
    case worst = "최악"
    
    var id: String { self.rawValue }
    
    /// 감정별 이모티콘
    var emoji: String {
        switch self {
        case .veryGood: return "🥰"
        case .good: return "😊"
        case .neutral: return "😐"
        case .bad: return "😞"
        case .worst: return "😫"
        }
    }
    
    /// 감정별 테마 색상
    var color: Color {
        switch self {
        case .veryGood: return Color(hex: "FF9AA2") // 파스텔 핑크
        case .good: return Color(hex: "FFB7B2")     // 파스텔 살구
        case .neutral: return Color(hex: "E2F0CB")  // 파스텔 연두
        case .bad: return Color(hex: "B5EAD7")      // 파스텔 민트
        case .worst: return Color(hex: "C7CEEA")    // 파스텔 블루
        }
    }
    
    /// 감정 점수 (통계용, 1-5)
    var score: Int {
        switch self {
        case .veryGood: return 5
        case .good: return 4
        case .neutral: return 3
        case .bad: return 2
        case .worst: return 1
        }
    }
    
    /// Gemini AI 프롬프트용 영문 설명
    var englishDescription: String {
        switch self {
        case .veryGood: return "very happy and energetic"
        case .good: return "good and content"
        case .neutral: return "neutral and calm"
        case .bad: return "bad and feeling down"
        case .worst: return "terrible and depressed"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, ((int >> 4) & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
