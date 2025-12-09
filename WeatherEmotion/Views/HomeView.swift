//
//  HomeView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var emotionViewModel = EmotionViewModel()
    @State private var showRecommendation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경색 (날씨에 따라 변경)
                if let weather = weatherViewModel.weather {
                    LinearGradient(
                        gradient: Gradient(colors: weather.gradientColors.map { Color(hex: $0) }),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                } else {
                    Color.gray.opacity(0.1).ignoresSafeArea(edges: .top)
                }
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // 1. 상단: 날씨 정보 영역 (40%)
                        weatherSection
                            .frame(height: geometry.size.height * 0.4)
                        
                        // 2. 하단: 감정 선택 영역 (60%)
                        emotionSection
                            .frame(height: geometry.size.height * 0.6)
                            .background(Color.white)
                            .cornerRadius(30, corners: [.topLeft, .topRight])
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                    }
                }
            }
            .onAppear {
                print("🏠 HomeView appeared")
                weatherViewModel.requestPermission()
                weatherViewModel.loadWeather()
            }
            .alert(isPresented: $weatherViewModel.showPermissionAlert) {
                Alert(
                    title: Text("위치 권한 필요"),
                    message: Text(weatherViewModel.errorMessage ?? ""),
                    primaryButton: .default(Text("설정으로 이동"), action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showRecommendation) {
                if let weather = weatherViewModel.weather,
                   let emotion = emotionViewModel.selectedEmotion {
                    ActivityRecommendationView(weather: weather, emotion: emotion)
                }
            }
        }
    }
    
    // MARK: - Weather Section
    private var weatherSection: some View {
        VStack(spacing: 10) {
            Spacer()
            
            if weatherViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if let weather = weatherViewModel.weather {
                // 날씨 아이콘
                Image(systemName: weather.weatherIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .symbolRenderingMode(.multicolor)
                
                // 온도
                Text(weather.displayTemperature)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                // 날씨 상태
                Text(weather.localizedCondition)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                // 위치
                HStack {
                    Image(systemName: "location.fill")
                    Text(weather.location)
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 5)
            } else {
                Text("날씨 정보를 불러오는 중...")
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Emotion Section
    private var emotionSection: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 15)
                
                Text("오늘 기분이 어때요?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 10)
            }
            
            // 감정 선택 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 15) {
                ForEach(Emotion.allCases) { emotion in
                    VStack {
                        Text(emotion.emoji)
                            .font(.system(size: 40))
                            .scaleEffect(emotionViewModel.selectedEmotion == emotion ? 1.2 : 1.0)
                            .animation(.spring(), value: emotionViewModel.selectedEmotion)
                        
                        Text(emotion.rawValue)
                            .font(.caption)
                            .foregroundColor(emotionViewModel.selectedEmotion == emotion ? .primary : .gray)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(emotionViewModel.selectedEmotion == emotion ? emotion.color.opacity(0.3) : Color.clear)
                    )
                    .onTapGesture {
                        withAnimation {
                            emotionViewModel.selectEmotion(emotion)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 추천 받기 버튼
            Button(action: {
                showRecommendation = true
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("활동 추천 받기")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(emotionViewModel.selectedEmotion != nil ? Color.blue : Color.gray)
                )
            }
            .disabled(emotionViewModel.selectedEmotion == nil)
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Corner Radius Helper
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
