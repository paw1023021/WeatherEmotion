import SwiftUI

@main
struct WeatherEmotionApp: App {
    // CoreData 초기화
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
