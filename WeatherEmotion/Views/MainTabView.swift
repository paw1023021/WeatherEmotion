//
//  MainTabView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // 1. 홈 탭
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
            
            // 2. 활동 기록 탭
            ActivityLogView()
                .tabItem {
                    Label("기록", systemImage: "list.bullet.clipboard")
                }
            
            // 3. 통계 탭
            StatsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar.fill")
                }
            
            // 4. 설정 탭
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
        .accentColor(Color(hex: "6A5ACD")) // 포인트 컬러 설정
    }
}
