//
//  SettingsView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var showingResetAlert = false
    @State private var showingResetSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // 1. 일반 설정
                Section(header: Text("일반")) {
                    HStack {
                        Text("언어")
                        Spacer()
                        Text("한국어")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                // 2. 데이터 관리
                Section(header: Text("데이터 관리")) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Text("모든 데이터 초기화")
                            .foregroundColor(.red)
                    }
                    
                    // [개발자용] 샘플 데이터 생성
                    Button(action: {
                        CoreDataManager.shared.createSampleData()
                    }) {
                        Text("샘플 데이터 생성 (테스트용)")
                            .foregroundColor(.blue)
                    }
                }
                
                // 3. 앱 정보
                Section(header: Text("정보")) {
                    Link("개인정보 처리방침", destination: URL(string: "https://example.com/privacy")!)
                    Link("문의하기", destination: URL(string: "mailto:support@example.com")!)
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("WeatherEmotion Team")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("설정")
            // 초기화 확인 알림
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("데이터 초기화"),
                    message: Text("정말로 모든 활동 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다."),
                    primaryButton: .destructive(Text("삭제")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
            // 초기화 완료 알림 (Alert 겹침 방지를 위해 별도 처리 필요할 수 있으으나, 순차적이면 괜찮음)
            // SwiftUI Alert 중첩 제한 고려: 리셋 후 간단히 햅틱 피드백이나 다른 방법도 좋음.
            // 여기선 간단히 로그만 찍고 끝내거나 UI 업데이트.
        }
    }
    
    private func resetAllData() {
        // CoreData의 모든 DailyLog 삭제
        CoreDataManager.shared.deleteAllLogs()
        
        // UserDefaults 등 기타 데이터가 있다면 초기화
        // 예: WeatherService의 캐시 등
        UserDefaults.standard.removeObject(forKey: "cachedWeather")
        
        print("✅ 모든 데이터가 초기화되었습니다.")
    }
}
