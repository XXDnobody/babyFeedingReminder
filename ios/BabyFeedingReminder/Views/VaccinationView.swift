import SwiftUI

/// 疫苗接种视图
struct VaccinationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = VaccinationViewModel()
    @State private var selectedTab = 0  // 0-接种计划 1-疫苗时间表
    @State private var showRecordSheet = false
    @State private var selectedRecord: VaccinationRecord?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 统计卡片
                    statisticsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // 切换标签
                    Picker("", selection: $selectedTab) {
                        Text("接种计划").tag(0)
                        Text("疫苗时间表").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("加载中...")
                        Spacer()
                    } else {
                        if selectedTab == 0 {
                            vaccinationPlanList
                        } else {
                            vaccineScheduleList
                        }
                    }
                }
            }
            .navigationTitle("疫苗接种")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await viewModel.loadData(babyId: appState.selectedBaby?.id)
            }
        }
        .onChange(of: appState.selectedBaby?.id) { _, newValue in
            Task {
                await viewModel.loadData(babyId: newValue)
            }
        }
        .sheet(isPresented: $showRecordSheet) {
            if let record = selectedRecord, let babyId = appState.selectedBaby?.id {
                VaccinationRecordSheet(
                    record: record,
                    babyId: babyId,
                    viewModel: viewModel
                )
                .environment(\.locale, Locale(identifier: "zh_CN"))
            }
        }
    }
    
    // MARK: - 统计卡片
    
    private var statisticsCard: some View {
        HStack(spacing: 16) {
            statisticItem(
                title: "已接种",
                value: "\(viewModel.completedCount)",
                color: .green
            )
            statisticItem(
                title: "待接种",
                value: "\(viewModel.pendingCount)",
                color: .blue
            )
            statisticItem(
                title: "已逾期",
                value: "\(viewModel.overdueCount)",
                color: .red
            )
            statisticItem(
                title: "完成率",
                value: String(format: "%.0f%%", viewModel.completionRate * 100),
                color: .purple
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func statisticItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 接种计划列表
    
    private var vaccinationPlanList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 逾期提醒
                if !viewModel.overdueVaccinations.isEmpty {
                    overdueSection
                }
                
                // 即将到期
                if !viewModel.upcomingVaccinations.isEmpty {
                    upcomingSection
                }
                
                // 所有疫苗
                allVaccinationsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("已逾期")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            
            ForEach(viewModel.overdueVaccinations) { record in
                VaccinationRecordRow(record: record) {
                    selectedRecord = record
                    showRecordSheet = true
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("即将到期（30天内）")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(viewModel.upcomingVaccinations) { record in
                VaccinationRecordRow(record: record) {
                    selectedRecord = record
                    showRecordSheet = true
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var allVaccinationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("全部疫苗")
                .font(.headline)
                .padding(.top, 8)
            
            ForEach(viewModel.vaccinationRecords) { record in
                VaccinationRecordRow(record: record) {
                    selectedRecord = record
                    showRecordSheet = true
                }
            }
        }
    }
    
    // MARK: - 疫苗时间表
    
    private var vaccineScheduleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.vaccineSchedule) { schedule in
                    VaccineScheduleRow(schedule: schedule)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - 疫苗记录行

struct VaccinationRecordRow: View {
    let record: VaccinationRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 状态图标
                statusIcon
                
                // 疫苗信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.vaccineName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("第\(record.doseNumber)剂")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if let scheduledDate = record.scheduledDate {
                        Text("计划日期：\(formatDate(scheduledDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let actualDate = record.actualDate {
                        Text("接种日期：\(formatDate(actualDate))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // 状态标签
                Text(record.statusDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                if record.canRecord {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(!record.canRecord && record.status != 1)
    }
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: statusIconName)
                .font(.system(size: 18))
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch record.status {
        case 0: return .blue
        case 1: return .green
        case 2: return .red
        case 3: return .gray
        default: return .gray
        }
    }
    
    private var statusIconName: String {
        switch record.status {
        case 0: return "clock"
        case 1: return "checkmark.circle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 3: return "xmark.circle"
        default: return "questionmark.circle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 疫苗时间表行

struct VaccineScheduleRow: View {
    let schedule: VaccineSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(schedule.vaccineName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("第\(schedule.doseNumber)剂")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Spacer()
                
                if let desc = schedule.ageDescription {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let fullName = schedule.vaccineFullName {
                Text(fullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                if let desc = schedule.description {
                    Label(desc, systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let site = schedule.injectionSite {
                    Label(site, systemImage: "syringe")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if let notes = schedule.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 接种记录表单

struct VaccinationRecordSheet: View {
    @Environment(\.dismiss) var dismiss
    let record: VaccinationRecord
    let babyId: Int64
    @ObservedObject var viewModel: VaccinationViewModel
    
    @State private var actualDate = Date()
    @State private var vaccinationSite = ""
    @State private var batchNumber = ""
    @State private var reaction = ""
    @State private var remark = ""
    @State private var isSaving = false
    @State private var showSkipAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("疫苗信息") {
                    LabeledContent("疫苗名称", value: record.vaccineName)
                    LabeledContent("剂次", value: "第\(record.doseNumber)剂")
                    if let scheduledDate = record.scheduledDate {
                        LabeledContent("计划日期", value: formatDate(scheduledDate))
                    }
                }
                
                Section("接种信息") {
                    DatePicker("接种日期", selection: $actualDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    TextField("接种地点", text: $vaccinationSite)
                    TextField("疫苗批号", text: $batchNumber)
                }
                
                Section("接种后反应") {
                    TextField("记录接种后反应（如有）", text: $reaction, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("备注") {
                    TextField("备注信息（可选）", text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                if record.status == 0 || record.status == 2 {
                    Section {
                        Button(role: .destructive) {
                            showSkipAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("跳过此疫苗")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(record.status == 1 ? "查看接种记录" : "记录接种")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let date = record.actualDate {
                    actualDate = date
                }
                vaccinationSite = record.vaccinationSite ?? ""
                batchNumber = record.batchNumber ?? ""
                reaction = record.reaction ?? ""
                remark = record.remark ?? ""
            }
            .alert("确认跳过", isPresented: $showSkipAlert) {
                Button("取消", role: .cancel) { }
                Button("确认跳过", role: .destructive) {
                    skipVaccination()
                }
            } message: {
                let msg = "确定要跳过【\(record.vaccineName) 第\(record.doseNumber)剂】吗？跳过后可在列表中查看。"
                Text(msg)
            }
        }
    }
    
    private func saveRecord() {
        isSaving = true
        Task {
            let success = await viewModel.recordVaccination(
                babyId: babyId,
                vaccineCode: record.vaccineCode,
                vaccineName: record.vaccineName,
                doseNumber: record.doseNumber,
                actualDate: actualDate,
                vaccinationSite: vaccinationSite.isEmpty ? nil : vaccinationSite,
                batchNumber: batchNumber.isEmpty ? nil : batchNumber,
                reaction: reaction.isEmpty ? nil : reaction,
                remark: remark.isEmpty ? nil : remark,
                recordId: record.id
            )
            
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
    
    private func skipVaccination() {
        Task {
            let success = await viewModel.skipVaccination(id: record.id, babyId: babyId)
            if success {
                dismiss()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    VaccinationView()
        .environmentObject(AppState())
}
