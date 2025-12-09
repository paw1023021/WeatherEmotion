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
    
    // 주간 데이터 (최근 7일)
    @Published var weeklyLogs: [DailyLog] = []
    @Published var weeklyCompletionRate: Double = 0.0
    
    // 월간 데이터 (이번 달)
    @Published var monthlyLogs: [DailyLog] = []
    @Published var monthlyCompletionRate: Double = 0.0
    
    // 캘린더용 데이터 (날짜별 매핑)
    @Published var logsDictionary: [String: DailyLog] = [:]
    
    // 차트 데이터
    @Published var emotionTrend: [EmotionTrendData] = []
    
    // MARK: - Initialization
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        fetchLogs()
        
        // CoreData 변경 감지 (다른 뷰에서 수정/삭제/추가 시 자동 갱신)
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataManager.shared.context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                print("🔄 CoreData 변경 감지됨 -> 통계 갱신")
                self?.fetchLogs()
            }
            .store(in: &cancellables)
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
        fetchLogs() // 데이터 갱신
    }
    
    /// 기록 삭제
    func deleteLog(at offsets: IndexSet) {
        offsets.forEach { index in
            let log = logs[index]
            CoreDataManager.shared.deleteLog(log)
        }
        fetchLogs()
    }
    
    /// 특정 날짜의 로그 가져오기
    func getLog(for date: Date) -> DailyLog? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return logsDictionary[key]
    }
    
    // MARK: - Private Methods
    
    /// 통계 데이터 계산
    private func updateStats() {
        let calendar = Calendar.current
        let now = Date()
        
        // 0. 캘린더용 딕셔너리 생성
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 같은 날짜에 여러 로그가 있을 경우, 가장 최근 것을 사용하거나 특정 로직으로 선택
        // 여기서는 가장 최근 로그를 사용
        self.logsDictionary = Dictionary(grouping: logs, by: { log in
            guard let date = log.date else { return "" }
            return formatter.string(from: date)
        }).compactMapValues { $0.first } // 최신순 정렬되어 있으므로 첫 번째가 가장 최신
        
        // 1. 주간 데이터 필터링 (최근 7일)
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else { return }
        
        self.weeklyLogs = logs.filter { log in
            guard let date = log.date else { return false }
            return date >= oneWeekAgo
        }.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        
        // 주간 완료율 계산
        let weeklyTotal = Double(weeklyLogs.count)
        let weeklyCompleted = Double(weeklyLogs.filter { $0.activityCompleted }.count)
        self.weeklyCompletionRate = weeklyTotal > 0 ? weeklyCompleted / weeklyTotal : 0.0
        
        // 2. 월간 데이터 필터링 (이번 달)
        let currentComponents = calendar.dateComponents([.year, .month], from: now)
        
        self.monthlyLogs = logs.filter { log in
            guard let date = log.date else { return false }
            let logComponents = calendar.dateComponents([.year, .month], from: date)
            return logComponents.year == currentComponents.year && logComponents.month == currentComponents.month
        }.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        
        // 월간 완료율 계산
        let monthlyTotal = Double(monthlyLogs.count)
        let monthlyCompleted = Double(monthlyLogs.filter { $0.activityCompleted }.count)
        self.monthlyCompletionRate = monthlyTotal > 0 ? monthlyCompleted / monthlyTotal : 0.0
        
        // 3. 감정 변화 추이 (주간 데이터 기반 - 일별 요약)
        // 같은 날짜끼리 그룹화
        let groupedLogs = Dictionary(grouping: weeklyLogs) { log -> String in
            guard let date = log.date else { return "" }
            return formatter.string(from: date)
        }
        
        // 날짜 오름차순 정렬된 키
        let sortedKeys = groupedLogs.keys.sorted()
        
        self.emotionTrend = sortedKeys.compactMap { key -> EmotionTrendData? in
            guard let logs = groupedLogs[key], !logs.isEmpty else { return nil }
            
            // a. 평균 점수 계산
            let totalScore = logs.reduce(0) { $0 + ($1.emotion?.score ?? 0) }
            let averageScore = Int(round(Double(totalScore) / Double(logs.count)))
            
            // b. 대표 감정 (가장 많이 기록된 것, 없으면 평균 점수와 가까운 것)
            // 빈도수 계산
            let emotionCounts = logs.reduce(into: [Emotion: Int]()) { counts, log in
                if let emotion = log.emotion {
                    counts[emotion, default: 0] += 1
                }
            }
            // 최빈 감정 찾기
            let representativeEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key
                                        ?? Emotion.allCases.first(where: { $0.score == averageScore }) 
                                        ?? .neutral
            
            // c. 날짜 객체 다시 생성 (해당 날짜의 12:00 PM 등으로 통일하여 차트 정렬 보장)
            // logs의 첫 번째 날짜 사용하되 시간은 무시될 것임 (Chart에서 .day 단위 사용 시)
            guard let firstLogDate = logs.first?.date else { return nil }
            let normalizedDate = calendar.startOfDay(for: firstLogDate)
            
            return EmotionTrendData(date: normalizedDate, score: averageScore, emotion: representativeEmotion)
        }.sorted { $0.date < $1.date }
    }
}
