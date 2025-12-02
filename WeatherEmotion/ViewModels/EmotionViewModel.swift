//
//  EmotionViewModel.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import Combine

// MARK: - EmotionViewModel
/// 감정 선택 화면의 상태를 관리하는 ViewModel
@MainActor
class EmotionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedEmotion: Emotion?
    
    // MARK: - Public Methods
    
    /// 감정 선택
    func selectEmotion(_ emotion: Emotion) {
        self.selectedEmotion = emotion
    }
    
    /// 감정 기록 저장 (활동 없이 저장)
    /// - Parameter weather: 현재 날씨 정보
    func saveEmotionLog(weather: Weather) {
        guard let emotion = selectedEmotion else { return }
        
        // CoreData에 저장 (Activity는 nil)
        CoreDataManager.shared.createLog(emotion: emotion, weather: weather, activity: nil)
    }
}
