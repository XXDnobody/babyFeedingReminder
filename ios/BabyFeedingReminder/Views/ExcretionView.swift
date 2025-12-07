import SwiftUI

struct ExcretionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ExcretionViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showAddRecord = false
    @State private var editingRecord: ExcretionRecord? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 固定标题区域
                    HStack {
                        Text("排便记录")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        
                        // 装饰图标
                        Image(systemName: "toilet.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.excretionColor.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // 网络状态提示
                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                            Text("网络不见了，请检查网络")
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                    }

                    // 排泄类型选择器
                    ExcretionTypeSelector(
                        selectedType: $viewModel.selectedExcretionType,
                        poopCount: viewModel.poopCount,
                        peeCount: viewModel.peeCount
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // 今日记录列表
                    List {
                        Section {
                            ForEach(viewModel.todayRecords) { record in
                                ExcretionRecordRow(record: record)
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingRecord = record
                                    }
                            }
                            .onDelete { offsets in
                                Task {
                                    await viewModel.deleteRecords(at: offsets)
                                }
                            }
                        } header: {
                            HStack {
                                Text("今日记录")
                                Spacer()
                                Text("大便\(viewModel.poopCount)次，小便\(viewModel.peeCount)次")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadTodayRecords(babyId: appState.selectedBaby?.id)
                    }
                    
                    // 底部添加按钮
                    Button {
                        showAddRecord = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("添加排便记录")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.excretionButtonGradient)
                        .cornerRadius(AppTheme.cardRadius)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddRecord) {
            EditExcretionRecordView(viewModel: viewModel, record: nil)
        }
        .sheet(item: $editingRecord) { record in
            EditExcretionRecordView(viewModel: viewModel, record: record)
        }
        .onAppear {
            Task {
                await viewModel.loadTodayRecords(babyId: appState.selectedBaby?.id)
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - 排泄类型选择器
struct ExcretionTypeSelector: View {
    @Binding var selectedType: Int
    var poopCount: Int = 0
    var peeCount: Int = 0
    var allCount: Int { poopCount + peeCount }
    
    var body: some View {
        HStack(spacing: 12) {
            ExcretionTypeButton(type: 0, selectedType: $selectedType, title: "全部", icon: "list.bullet", count: allCount)
            ExcretionTypeButton(type: 1, selectedType: $selectedType, title: "大便", icon: "toilet.fill", count: poopCount)
            ExcretionTypeButton(type: 2, selectedType: $selectedType, title: "小便", icon: "drop.fill", count: peeCount)
        }
    }
}

struct ExcretionTypeButton: View {
    let type: Int
    @Binding var selectedType: Int
    let title: String
    let icon: String
    var count: Int = 0
    
    var isSelected: Bool { selectedType == type }
    
    var body: some View {
        Button {
            selectedType = type
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                HStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                    if count > 0 {
                        Text("(\(count))")
                            .font(.caption2)
                    }
                }
            }
            .frame(width: 75)
            .padding(.vertical, 12)
            .background(
                isSelected 
                    ? AppTheme.excretionColor.opacity(0.15)
                    : Color.white
            )
            .foregroundColor(isSelected ? AppTheme.excretionColor : AppTheme.secondaryText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.excretionColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.cardShadowColor, radius: isSelected ? 4 : 2, x: 0, y: 2)
        }
    }
}

// MARK: - 排泄记录行
struct ExcretionRecordRow: View {
    let record: ExcretionRecord
    
    var body: some View {
        HStack {
            // 类型图标
            ZStack {
                Circle()
                    .fill(record.excretionType == 1 ? Color.brown.opacity(0.2) : Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: record.excretionTypeIcon)
                    .font(.system(size: 18))
                    .foregroundColor(record.excretionType == 1 ? .brown : .yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.excretionTypeDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primaryText)
                    
                    if record.isAbnormal {
                        Text("异常")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(timeString(record.recordTime))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    if let color = record.color, !color.isEmpty {
                        Text(color)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    if let texture = record.texture, !texture.isEmpty {
                        Text(texture)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            if let amount = record.amount, !amount.isEmpty {
                Text(amount)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.excretionColor.opacity(0.1))
                    .foregroundColor(AppTheme.excretionColor)
                    .cornerRadius(8)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.cardShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 编辑排泄记录视图
struct EditExcretionRecordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: ExcretionViewModel
    let record: ExcretionRecord?  // nil 表示新增，否则是编辑
    
    @State private var excretionType = 1
    @State private var recordTime = Date()
    @State private var selectedColor = ""
    @State private var selectedTexture = ""
    @State private var selectedAmount = ""
    @State private var hasAbnormal = 0
    @State private var remark = ""
    @State private var showDeleteAlert = false
    @State private var isInitialized = false
    
    // 大便颜色选项
    private let colorOptions = ["黄色", "绿色", "棕色", "黑色", "白色", "红色"]
    // 大便性状选项
    private let textureOptions = ["稀", "软", "硬", "颗粒状", "水状", "正常"]
    // 量选项
    private let amountOptions = ["少量", "适中", "大量"]
    
    private var isEditMode: Bool { record != nil }
    private var title: String { isEditMode ? "编辑记录" : "添加记录" }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    Picker("类型", selection: $excretionType) {
                        Text("大便").tag(1)
                        Text("小便").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("时间", selection: $recordTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                
                // 大便特有选项
                if excretionType == 1 {
                    Section("大便详情") {
                        // 颜色选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("颜色")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                                ForEach(colorOptions, id: \.self) { color in
                                    ColorOptionButton(
                                        title: color,
                                        isSelected: selectedColor == color,
                                        action: { selectedColor = selectedColor == color ? "" : color }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 性状选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("性状")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                                ForEach(textureOptions, id: \.self) { texture in
                                    ColorOptionButton(
                                        title: texture,
                                        isSelected: selectedTexture == texture,
                                        action: { selectedTexture = selectedTexture == texture ? "" : texture }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("量") {
                    HStack(spacing: 12) {
                        ForEach(amountOptions, id: \.self) { amount in
                            Button {
                                selectedAmount = selectedAmount == amount ? "" : amount
                            } label: {
                                Text(amount)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedAmount == amount ? AppTheme.excretionColor : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedAmount == amount ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("异常标记") {
                    Toggle("标记为异常", isOn: Binding(
                        get: { hasAbnormal == 1 },
                        set: { hasAbnormal = $0 ? 1 : 0 }
                    ))
                    
                    if hasAbnormal == 1 {
                        Text("请在备注中描述异常情况，必要时咨询医生")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("备注") {
                    TextField("添加备注...", text: $remark, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // 编辑模式下显示删除按钮
                if isEditMode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("删除记录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            if let record = record {
                                await viewModel.updateRecord(
                                    id: record.id,
                                    excretionType: excretionType,
                                    recordTime: recordTime,
                                    color: excretionType == 1 ? selectedColor : nil,
                                    texture: excretionType == 1 ? selectedTexture : nil,
                                    amount: selectedAmount.isEmpty ? nil : selectedAmount,
                                    hasAbnormal: hasAbnormal,
                                    remark: remark
                                )
                            } else {
                                await viewModel.addRecord(
                                    excretionType: excretionType,
                                    recordTime: recordTime,
                                    color: excretionType == 1 ? selectedColor : nil,
                                    texture: excretionType == 1 ? selectedTexture : nil,
                                    amount: selectedAmount.isEmpty ? nil : selectedAmount,
                                    hasAbnormal: hasAbnormal,
                                    remark: remark
                                )
                            }
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if !isInitialized {
                    if let record = record {
                        // 编辑模式：使用记录中的值
                        excretionType = record.excretionType
                        recordTime = record.recordTime
                        selectedColor = record.color ?? ""
                        selectedTexture = record.texture ?? ""
                        selectedAmount = record.amount ?? ""
                        hasAbnormal = record.hasAbnormal ?? 0
                        remark = record.remark ?? ""
                    }
                    isInitialized = true
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let record = record {
                        Task {
                            await viewModel.deleteRecord(id: record.id)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要删除这条记录吗？此操作不可撤销。")
            }
        }
    }
}

// MARK: - 颜色/性状选择按钮
struct ColorOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.excretionColor : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExcretionView()
        .environmentObject(AppState())
}
