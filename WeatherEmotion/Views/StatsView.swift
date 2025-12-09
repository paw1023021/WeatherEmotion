//
//  StatsView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedPeriod = 0 // 0: 주간, 1: 월간
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 기간 선택 Picker
                    Picker("기간", selection: $selectedPeriod) {
                        Text("주간").tag(0)
                        Text("월간").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedPeriod == 0 {
                        // 주간 통계 (Weekly)
                        weeklyStatsView
                    } else {
                        // 월간 통계 (Monthly)
                        monthlyStatsView
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("통계")
            .background(Color(hex: "F9F9F9"))
            .onAppear {
                viewModel.fetchLogs()
            }
        }
    }
    
    // MARK: - Weekly View
    
    private var weeklyStatsView: some View {
        VStack(spacing: 25) {
            // 1. 주간 완료율 카드
            VStack {
                Text("이번 주 활동 달성률")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 15.0)
                        .opacity(0.3)
                        .foregroundColor(Color.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(viewModel.weeklyCompletionRate, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: viewModel.weeklyCompletionRate)
                    
                    Text(String(format: "%.0f%%", viewModel.weeklyCompletionRate * 100.0))
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(width: 120, height: 120)
                .padding()
                
                Text("총 \(viewModel.weeklyLogs.count)개 중 \(Int(viewModel.weeklyLogs.count * Int(viewModel.weeklyCompletionRate * 100) / 100))개 완료")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // 2. 주간 감정 흐름 차트
            if !viewModel.emotionTrend.isEmpty {
                VStack(alignment: .leading) {
                    Text("주간 감정 흐름")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Chart {
                        ForEach(viewModel.emotionTrend) { data in
                            LineMark(
                                x: .value("날짜", data.date, unit: .day),
                                y: .value("감정 점수", data.score)
                            )
                            .interpolationMethod(.catmullRom) // 부드러운 곡선
                            .symbol(Circle().strokeBorder(lineWidth: 2)) // 점 모양 통일
                            
                            PointMark(
                                x: .value("날짜", data.date, unit: .day),
                                y: .value("감정 점수", data.score)
                            )
                            .foregroundStyle(data.emotion.color) // 점 색상은 감정 색상으로
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0.5...5.5) // 1~5점 구간을 꽉 차게 표시
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    switch intValue {
                                    case 5: Text("🥰")
                                    case 4: Text("😊")
                                    case 3: Text("😐")
                                    case 2: Text("😞")
                                    case 1: Text("😫")
                                    default: Text("")
                                    }
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
            
            // 3. 주간 활동 목록
            VStack(alignment: .leading) {
                Text("이번 주 활동 목록")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.weeklyLogs.isEmpty {
                    Text("이번 주 기록이 없습니다.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.weeklyLogs) { log in
                            HStack {
                                Text("\(log.dateString)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text(log.activityTitle ?? "")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if log.activityCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Monthly View
    
    private var monthlyStatsView: some View {
        VStack(spacing: 25) {
            // 1. 감정 캘린더 (Mood Calendar)
            VStack(alignment: .leading) {
                Text(Date().formatted(.dateTime.year().month()))
                    .font(.headline)
                    .padding(.bottom, 10)
                
                // 요일 헤더
                HStack {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 날짜 그리드
                MoodCalendarView(viewModel: viewModel)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // 2. 월간 활동 목록 (일별 표시)
            VStack(alignment: .leading) {
                Text("월간 활동 내역")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.monthlyLogs.isEmpty {
                    Text("이번 달 기록이 없습니다.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.monthlyLogs) { log in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(log.dateString)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text(log.activityTitle ?? "")
                                        .font(.subheadline)
                                }
                                Spacer()
                                Text(log.emotion?.emoji ?? "")
                                    .font(.title2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Mood Calendar Component
struct MoodCalendarView: View {
    @ObservedObject var viewModel: StatsViewModel
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(calendarDays, id: \.self) { date in
                if let date = date {
                    VStack {
                        if let log = viewModel.getLog(for: date), let emotion = log.emotion {
                            Text(emotion.emoji)
                                .font(.system(size: 24))
                        } else {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(height: 40)
                    .background(
                        Circle()
                            .fill(containerColor(for: date))
                            .opacity(0.1)
                    )
                } else {
                    Text("") // 공백
                        .frame(height: 40)
                }
            }
        }
    }
    
    private func containerColor(for date: Date) -> Color {
        guard let log = viewModel.getLog(for: date), let emotion = log.emotion else {
            return Color.clear
        }
        return emotion.color
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 1: 일요일 ~ 7: 토요일
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}
