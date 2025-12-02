
import Foundation

// MARK: - Activity Model
/// 추천 활동 정보를 담는 데이터 모델
struct Activity: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String              // 활동 제목 (예: "따뜻한 차 마시기")
    let description: String         // 활동 상세 설명
    let tags: [String]              // 태그 (예: ["실내", "휴식", "따뜻함"])
    
    // 기본 생성자
    init(id: UUID = UUID(), title: String, description: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case title, description, tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // 디코딩 시 자동 생성
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.tags = try container.decode([String].self, forKey: .tags)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
    }
    
    // MARK: - Helper Properties
    
    /// 태그를 하나의 문자열로 결합 (예: "#실내 #휴식")
    var tagsString: String {
        return tags.map { "#\($0)" }.joined(separator: " ")
    }
    
    // MARK: - Default Activities (Fallback)
    /// API 응답 실패 시 보여줄 기본 추천 활동 목록
    static let defaults: [Activity] = [
        Activity(title: "가벼운 산책하기", description: "신선한 공기를 마시며 기분을 전환해보세요.", tags: ["야외", "운동", "기분전환"]),
        Activity(title: "따뜻한 차 한 잔", description: "좋아하는 차를 마시며 잠시 여유를 가져보세요.", tags: ["실내", "휴식", "티타임"]),
        Activity(title: "좋아하는 음악 듣기", description: "기분에 맞는 음악 플레이리스트를 감상해보세요.", tags: ["실내", "음악", "감성"]),
        Activity(title: "독서하기", description: "읽고 싶었던 책을 읽으며 마음의 양식을 쌓아보세요.", tags: ["실내", "독서", "집중"]),
        Activity(title: "스트레칭", description: "굳어있는 몸을 풀어주며 활력을 되찾으세요.", tags: ["실내", "운동", "건강"])
    ]
}

// MARK: - Gemini API Response Models
/// Gemini API로부터 받은 JSON 응답을 파싱하기 위한 구조체
struct GeminiActivityResponse: Codable {
    let activities: [Activity]
    
    // API 응답 예시:
    // {
    //   "activities": [
    //     { "title": "...", "description": "...", "tags": ["...", "..."] },
    //     ...
    //   ]
    // }
}

// Gemini API의 전체 응답 구조 (Content Generation)
struct GeminiContentResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}
