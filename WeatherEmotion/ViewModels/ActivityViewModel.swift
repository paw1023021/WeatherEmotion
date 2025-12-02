//
//  ActivityViewModel.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import Combine

// MARK: - ActivityViewModel
/// 활동 추천 및 선택 화면의 상태를 관리하는 ViewModel
@MainActor
class ActivityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recommendations: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let geminiService = GeminiService()
    
    // MARK: - Public Methods
    
    /// 활동 추천 받기
    /// - Parameters:
    ///   - emotion: 현재 감정
    ///   - weather: 현재 날씨
    func loadRecommendations(emotion: Emotion, weather: Weather) async {
        isLoading = true
        errorMessage = nil
        recommendations = []
        
        do {
            // Gemini API 호출
            let activities = try await geminiService.getRecommendations(emotion: emotion, weather: weather)
            self.recommendations = activities
        } catch {
            print("❌ 추천 실패: \(error.localizedDescription)")
            self.errorMessage = "활동 추천을 불러오는데 실패했습니다. 기본 추천을 표시합니다."
            // 실패 시 기본 추천 목록 사용
            self.recommendations = Activity.defaults
        }
        
        isLoading = false
    }
    
    /// 활동 선택 및 저장
    /// - Parameters:
    ///   - activity: 선택한 활동
    ///   - emotion: 현재 감정
    ///   - weather: 현재 날씨
    func selectActivity(_ activity: Activity, emotion: Emotion, weather: Weather) {
        // CoreData에 저장
        CoreDataManager.shared.createLog(emotion: emotion, weather: weather, activity: activity)
    }
}
