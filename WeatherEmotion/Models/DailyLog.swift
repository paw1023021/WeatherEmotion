//
//  DailyLog.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import CoreData

// MARK: - DailyLog Entity
/// 사용자의 하루 감정 및 활동 기록을 저장하는 CoreData Entity
@objc(DailyLog)
public class DailyLog: NSManagedObject, Identifiable {
    // MARK: - Attributes
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var emotionRawValue: String? // Emotion 열거형의 rawValue 저장
    @NSManaged public var weatherCondition: String?
    @NSManaged public var temperature: Double
    @NSManaged public var activityTitle: String?
    @NSManaged public var activityCompleted: Bool
    @NSManaged public var location: String?
    
    // MARK: - Computed Properties
    
    /// 저장된 emotionRawValue를 Emotion 열거형으로 변환
    var emotion: Emotion? {
        get {
            guard let rawValue = emotionRawValue else { return nil }
            return Emotion(rawValue: rawValue)
        }
        set {
            emotionRawValue = newValue?.rawValue
        }
    }
    
    /// 날짜 포맷 (예: "2025년 11월 25일")
    var dateString: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    // MARK: - Convenience Initializer
    @discardableResult
    convenience init(context: NSManagedObjectContext, emotion: Emotion, weather: Weather, activity: Activity?) {
        self.init(context: context)
        self.id = UUID()
        self.date = Date()
        self.emotion = emotion
        self.weatherCondition = weather.condition
        self.temperature = weather.temperature
        self.location = weather.location
        self.activityTitle = activity?.title
        self.activityCompleted = false
    }
}

// MARK: - Fetch Requests
extension DailyLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyLog> {
        return NSFetchRequest<DailyLog>(entityName: "DailyLog")
    }
    
    /// 날짜순 정렬된 모든 기록 가져오기
    static func fetchAll(in context: NSManagedObjectContext) -> [DailyLog] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyLog.date, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ DailyLog fetch error: \(error)")
            return []
        }
    }
}
