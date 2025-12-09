//
//  ActivityRecommendationView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI

struct ActivityRecommendationView: View {
    let weather: Weather
    let emotion: Emotion
    
    @StateObject private var viewModel = ActivityViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F5").ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.recommendations.isEmpty {
                        // 데이터가 있으면 (기본 추천 포함) 리스트 표시
                        activityListView
                    } else if let error = viewModel.errorMessage {
                        errorView(message: error)
                    }
                }
            }
            .navigationTitle("추천 활동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadRecommendations(emotion: emotion, weather: weather)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI가 활동을 찾고 있어요...")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            Button("다시 시도") {
                Task {
                    await viewModel.loadRecommendations(emotion: emotion, weather: weather)
                }
            }
        }
    }
    
    private var activityListView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 상단 요약 카드
                HStack {
                    VStack(alignment: .leading) {
                        Text("오늘의 날씨")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(weather.localizedCondition) \(weather.displayTemperature)")
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("나의 기분")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(emotion.emoji) \(emotion.rawValue)")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.top)
                
                // 에러 메시지 (기본 추천 사용 시)
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                }
                
                Text("이런 활동은 어떠세요?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // 추천 활동 리스트
                ForEach(viewModel.recommendations) { activity in
                    ActivityCard(activity: activity) {
                        viewModel.selectActivity(activity, emotion: emotion, weather: weather)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding(.bottom)
        }
    }
}

// MARK: - Activity Card Component
struct ActivityCard: View {
    let activity: Activity
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(activity.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                Text(activity.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 태그
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(activity.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}
