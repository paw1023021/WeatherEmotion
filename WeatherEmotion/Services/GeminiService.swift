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
    private let apiKey = "AIzaSyCvOxEnz9ca6mkZHWPs9dMFGBsFMUUuS4U"
    private let modelName = "gemini-pro" // 또는 gemini-pro
    
    // MARK: - Public Methods
    
    /// 날씨와 감정에 맞는 활동 추천 받기
    /// - Parameters:
    ///   - emotion: 현재 감정
    ///   - weather: 현재 날씨
    /// - Returns: 추천 활동 목록
    func getRecommendations(emotion: Emotion, weather: Weather) async throws -> [Activity] {
        // 1. URL 구성
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 2. 프롬프트 구성
        let prompt = """
        Recommend 3 activities for a user who feels '\(emotion.englishDescription)' and the weather is '\(weather.condition)' (\(weather.displayTemperature)).
        The response MUST be a valid JSON object with the following structure:
        {
            "activities": [
                {
                    "title": "Activity Title (in Korean)",
                    "description": "Short description (in Korean)",
                    "tags": ["tag1", "tag2"]
                }
            ]
        }
        Do not include any markdown formatting (like ```json). Just the raw JSON.
        """
        
        // 3. 요청 바디 구성
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json" // JSON 모드 강제
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. API 호출
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // 5. 응답 파싱
        // Gemini API 응답 구조 파싱
        let geminiResponse = try JSONDecoder().decode(GeminiContentResponse.self, from: data)
        
        guard let jsonText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        // 텍스트로 된 JSON을 실제 데이터 모델로 파싱
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let activityResponse = try JSONDecoder().decode(GeminiActivityResponse.self, from: jsonData)
        return activityResponse.activities
    }
}
