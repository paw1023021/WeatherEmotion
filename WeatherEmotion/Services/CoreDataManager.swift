//
//  CoreDataManager.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import CoreData

// MARK: - CoreDataManager
/// CoreData 스택을 관리하는 싱글톤 클래스
class CoreDataManager: ObservableObject {
    // MARK: - Shared Instance
    static let shared = CoreDataManager()
    
    // MARK: - Properties
    /// CoreData 컨테이너
    let container: NSPersistentContainer
    
    /// 메인 컨텍스트 (UI 작업용)
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Initialization
    private init() {
        // .xcdatamodeld 파일 이름과 일치해야 함
        container = NSPersistentContainer(name: "WeatherEmotion")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ CoreData 로딩 실패: \(error.localizedDescription)")
            } else {
                print("✅ CoreData 저장소 로드 성공: \(description.url?.absoluteString ?? "Unknown URL")")
            }
        }
        
        // 변경 사항 자동 병합 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Public Methods
    
    /// 변경 사항 저장
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData 저장 성공")
            } catch {
                print("❌ CoreData 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 새로운 일기 생성 (헬퍼 메서드)
    func createLog(emotion: Emotion, weather: Weather, activity: Activity?) {
        let _ = DailyLog(context: context, emotion: emotion, weather: weather, activity: activity)
        save()
    }
    
    /// 일기 삭제
    func deleteLog(_ log: DailyLog) {
        context.delete(log)
        save()
    }
    
    /// 모든 일기 삭제 (초기화용)
    func deleteAllLogs() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DailyLog.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.viewContext.execute(deleteRequest)
            // UI에 반영(삭제)된 내용을 알리기 위해 context 리셋 또는 save
            if container.viewContext.hasChanges {
                try container.viewContext.save()
            }
            // BatchDeleteRequest는 Context에 로드된 객체들을 자동으로 업데이트하지 않으므로
            // mergeChanges 또는 reset을 호출하거나, 여기서는 간단히 리셋
            container.viewContext.reset()
            print("✅ 모든 기록 삭제 완료")
        } catch {
            print("❌ 모든 기록 삭제 실패: \(error)")
        }
    }
    
    /// [테스트용] 샘플 데이터 생성 (최근 7일)
    func createSampleData() {
        let calendar = Calendar.current
        let now = Date()
        
        // 데이터 패턴: 나쁨 -> 보통 -> 좋음 -> 매우 좋음 -> 나쁨 -> 좋음 -> 보통
        let sampleData: [(offset: Int, emotion: Emotion, weather: String, temp: Double, title: String, completed: Bool)] = [
            (-6, .bad, "Rain", 15.0, "빗소리 듣기", true),
            (-5, .neutral, "Clouds", 18.0, "책 정리하기", false),
            (-4, .good, "Clear", 20.0, "동네 산책", true),
            (-3, .veryGood, "Clear", 24.0, "친구 약속", true),
            (-2, .worst, "Thunderstorm", 14.0, "낮잠 자기", false),
            (-1, .good, "Clouds", 21.0, "영화 감상", true),
            (0, .neutral, "Partly Cloudy", 19.0, "커피 마시기", false)
        ]
        
        for data in sampleData {
            if let date = calendar.date(byAdding: .day, value: data.offset, to: now) {
                // 이미 해당 날짜에 데이터가 있는지 확인하지 않고 그냥 추가 (테스트용이므로 중복 가능성 감수하거나 초기화 후 실행 권장)
                let log = DailyLog(context: context)
                log.id = UUID()
                log.date = date
                log.emotionRawValue = data.emotion.rawValue
                log.weatherCondition = data.weather
                log.temperature = data.temp
                log.activityTitle = data.title
                log.activityCompleted = data.completed
            }
        }
        
        save()
        print("✅ 샘플 데이터 생성 완료 (최근 7일)")
    }
}
