//
//  ActivityLogView.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import SwiftUI
import CoreData

struct ActivityLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 날짜 내림차순으로 모든 로그 가져오기
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyLog.date, ascending: false)],
        animation: .default)
    private var logs: FetchedResults<DailyLog>
    
    @State private var showingEditSheet = false
    @State private var selectedLog: DailyLog?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F5").ignoresSafeArea()
                
                if logs.isEmpty {
                    emptyStateView
                } else {
                    List {
                        // 1. 오늘의 할 일 (오늘 날짜 + 미완료)
                        if !todaysTasks.isEmpty {
                            Section(header: Text("오늘의 할 일").font(.headline)) {
                                ForEach(todaysTasks) { log in
                                    TaskRow(log: log)
                                        .onTapGesture {
                                            selectedLog = log
                                            showingEditSheet = true
                                        }
                                }
                                .onDelete(perform: deleteTodaysTask)
                            }
                        }
                        
                        // 2. 지난 기록 (나머지 또는 완료된 항목)
                        if !historyLogs.isEmpty {
                            Section(header: Text("지난 기록").font(.headline)) {
                                ForEach(historyLogs) { log in
                                    HistoryRow(log: log)
                                        .onTapGesture {
                                            selectedLog = log
                                            showingEditSheet = true
                                        }
                                }
                                .onDelete(perform: deleteHistoryLog)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("나의 기록")
            .sheet(item: $selectedLog) { log in
                EditLogView(log: log)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var todaysTasks: [DailyLog] {
        let calendar = Calendar.current
        return logs.filter { log in
            guard let date = log.date else { return false }
            return calendar.isDateInToday(date) && !log.activityCompleted
        }
    }
    
    private var historyLogs: [DailyLog] {
        let calendar = Calendar.current
        return logs.filter { log in
            guard let date = log.date else { return true }
            return !calendar.isDateInToday(date) || log.activityCompleted
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            Text("아직 기록이 없어요")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            Text("홈에서 감정을 선택하고\n활동을 추천받아보세요!")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    // MARK: - Actions
    
    private func deleteTodaysTask(at offsets: IndexSet) {
        withAnimation {
            offsets.map { todaysTasks[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func deleteHistoryLog(at offsets: IndexSet) {
        withAnimation {
            offsets.map { historyLogs[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Task Row (오늘의 할 일)
struct TaskRow: View {
    @ObservedObject var log: DailyLog
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        HStack {
            // 체크박스
            Button(action: {
                withAnimation {
                    log.activityCompleted.toggle()
                    try? viewContext.save()
                }
            }) {
                Image(systemName: log.activityCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(log.activityCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.activityTitle ?? "활동 없음")
                    .font(.headline)
                    .strikethrough(log.activityCompleted)
                    .foregroundColor(log.activityCompleted ? .gray : .primary)
                
                HStack {
                    Text(log.emotion?.rawValue ?? "")
                    Text("•")
                    Text("\(log.location ?? "") \(String(format: "%.1f", log.temperature))°C")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - History Row (지난 기록)
struct HistoryRow: View {
    @ObservedObject var log: DailyLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.dateString)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if log.activityCompleted {
                        Text("완료됨")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                Text(log.activityTitle ?? "활동 없음")
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text(log.emotion?.rawValue ?? "")
                    Text(log.emotion?.emoji ?? "")
                    Spacer()
                    Text(log.weatherCondition ?? "")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit View
struct EditLogView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var log: DailyLog
    
    @State private var editedTitle: String = ""
    @State private var isCompleted: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("활동 내용")) {
                    TextField("활동을 입력하세요", text: $editedTitle)
                    Toggle("활동 완료", isOn: $isCompleted)
                }
                
                Section(header: Text("상세 정보")) {
                    HStack {
                        Text("날짜")
                        Spacer()
                        Text(log.dateString)
                    }
                    HStack {
                        Text("감정")
                        Spacer()
                        Text("\(log.emotion?.emoji ?? "") \(log.emotion?.rawValue ?? "")")
                    }
                    HStack {
                        Text("날씨")
                        Spacer()
                        Text("\(log.weatherCondition ?? "") \(String(format: "%.1f", log.temperature))°C")
                    }
                }
                
                Section {
                    Button(action: deleteLog) {
                        Text("삭제하기")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("기록 수정")
            .navigationBarItems(
                leading: Button("취소") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("저장") { saveChanges() }
            )
            .onAppear {
                editedTitle = log.activityTitle ?? ""
                isCompleted = log.activityCompleted
            }
        }
    }
    
    private func saveChanges() {
        viewContext.performAndWait {
            log.activityTitle = editedTitle
            log.activityCompleted = isCompleted
            
            try? viewContext.save()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteLog() {
        viewContext.delete(log)
        try? viewContext.save()
        presentationMode.wrappedValue.dismiss()
    }
}
