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
}
