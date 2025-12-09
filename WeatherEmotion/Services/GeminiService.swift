//
//  GeminiService.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation

// MARK: - GeminiService
/// Google Gemini API를 사용하여 활동 추천을 생성하는 서비스
class GeminiService {
    // MARK: - Properties
    private let apiKey = "AIzaSyCco4pXym85HvzrNjnQF-d_FWQ8RsAu8Xc"
    private let modelName = "gemini-2.5-flash-lite"
    
    // MARK: - Public Methods
    
    /// 날씨와 감정에 맞는 활동 추천 받기
    /// - Parameters:
    ///   - emotion: 현재 감정
    ///   - weather: 현재 날씨
    /// - Returns: 추천 활동 목록
    func getRecommendations(emotion: Emotion, weather: Weather) async throws -> [Activity] {
        // 1. URL 구성
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        print("🤖 Gemini API 호출 시작")
        print("   모델: \(modelName)")
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 2. 프롬프트 구성 (JSON 형식 명시)
        let prompt = """
        사용자의 현재 상태:
        - 날씨: \(weather.localizedCondition), \(weather.displayTemperature)
        - 감정 상태: \(emotion.rawValue) (\(emotion.englishDescription))
        
        위 날씨와 감정의 조합에 가장 잘 어울리는 활동 3가지를 추천해주세요.
        
        [요구사항]
        1. **감정에 따른 활동 유형을 확실히 구분해주세요:**
           - **기분이 좋을 때 (Good, Happy):** 에너지를 쓰는 활동, **운동이나 스포츠**, 산책, 새로운 도전 등 **활기차고 동적인 활동**
           - **기분이 나쁠 때 (Bad, Sad, Tired):** 휴식, 명상, 따뜻한 차 마시기, 힐링 영화 보기 등 **정적인 활동 및 위로**
           - **보통일 때 (Neutral):** 가벼운 취미, 정리 등 **생산적이거나 소소한 활동**
           
        2. 날씨가 좋지 않다면(비, 눈, 미세먼지 등) 실내 활동을 우선시해주세요.
        3. 제목은 간결하게(15자 이내), 설명은 1-2문장으로 구체적인 방법을 포함해주세요.
        
        응답은 반드시 다음 JSON 형식으로만 작성하세요:
        {
            "activities": [
                {
                    "title": "활동 제목 (한글)",
                    "description": "활동 설명 (한글, 2문장 내외)",
                    "tags": ["태그1", "태그2", "태그3"]
                }
            ]
        }
        
        추가 설명 없이 JSON만 출력하세요.
        """
        
        // 3. 요청 바디 구성
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. API 호출
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ HTTP 응답 변환 실패")
            throw URLError(.badServerResponse)
        }
        
        print("📡 Gemini HTTP 상태: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            print("❌ Gemini API 에러: \(errorText)")
            throw URLError(.badServerResponse)
        }
        
        // 5. 응답 파싱
        let geminiResponse = try JSONDecoder().decode(GeminiContentResponse.self, from: data)
        
        guard let jsonText = geminiResponse.candidates.first?.content.parts.first?.text else {
            print("❌ JSON 텍스트 추출 실패")
            throw URLError(.cannotParseResponse)
        }
        
        print("📝 Gemini 응답 텍스트:")
        print(jsonText)
        
        // JSON 마크다운 제거 (```json ... ``` 형식 대응)
        var cleanedJSON = jsonText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            print("❌ UTF-8 변환 실패")
            throw URLError(.cannotDecodeContentData)
        }
        
        do {
            let activityResponse = try JSONDecoder().decode(GeminiActivityResponse.self, from: jsonData)
            print("✅ Gemini 추천 성공: \(activityResponse.activities.count)개")
            return activityResponse.activities
        } catch {
            print("❌ JSON 디코딩 실패: \(error)")
            print("   원본 JSON: \(cleanedJSON)")
            throw error
        }
    }
}
