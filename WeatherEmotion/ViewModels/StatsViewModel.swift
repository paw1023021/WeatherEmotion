//
//  StatsViewModel.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import CoreData
import Combine

// MARK: - Chart Data Models
/// 감정 변화 추이 데이터 모델
struct EmotionTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    let emotion: Emotion
}

/// 활동 빈도 데이터 모델
struct ActivityStatData: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
}

// MARK: - StatsViewModel
/// 통계 및 기록 화면의 상태를 관리하는 ViewModel
@MainActor
class StatsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var logs: [DailyLog] = []
    @Published var emotionTrend: [EmotionTrendData] = []
    @Published var activityStats: [ActivityStatData] = []
    
    // MARK: - Initialization
    init() {
        fetchLogs()
    }
    
    // MARK: - Public Methods
    
    /// 모든 기록 가져오기 및 통계 갱신
    func fetchLogs() {
        let context = CoreDataManager.shared.context
        self.logs = DailyLog.fetchAll(in: context)
        
        updateStats()
    }
    
    /// 활동 완료 상태 토글
    func toggleActivityCompletion(_ log: DailyLog) {
        log.activityCompleted.toggle()
        CoreDataManager.shared.save()
        
        // UI 갱신을 위해 다시 로드 (필요한 경우)
        objectWillChange.send()
    }
    
    /// 기록 삭제
    func deleteLog(at offsets: IndexSet) {
        offsets.forEach { index in
            let log = logs[index]
            CoreDataManager.shared.deleteLog(log)
        }
        fetchLogs()
    }
    
    // MARK: - Private Methods
    
    /// 통계 데이터 계산
    private func updateStats() {
        // 1. 감정 변화 추이 (최근 7일 또는 30일)
        // 날짜 오름차순 정렬
        let sortedLogs = logs.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        
        self.emotionTrend = sortedLogs.compactMap { log in
            guard let date = log.date, let emotion = log.emotion else { return nil }
            return EmotionTrendData(date: date, score: emotion.score, emotion: emotion)
        }
        
        // 2. 활동 통계 (상위 5개)
        var activityCounts: [String: Int] = [:]
        
        for log in logs {
            if let title = log.activityTitle {
                activityCounts[title, default: 0] += 1
            }
        }
        
        let sortedStats = activityCounts.map { title, count in
            ActivityStatData(title: title, count: count)
        }.sorted { $0.count > $1.count } // 빈도수 내림차순
        
        // 상위 5개만 표시
        self.activityStats = Array(sortedStats.prefix(5))
    }
}
