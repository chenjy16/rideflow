import SwiftUI

struct ModelView: View {
    @EnvironmentObject private var modelState: ModelState
    @EnvironmentObject private var chatState: ChatState
    @Binding var isRemoving: Bool

    @State private var isShowingDeletionConfirmation: Bool = false
    
    // 添加判断是否为第一个模型的计算属性
    private var isFirstModel: Bool {
        modelState.modelConfig.modelID == "Llama-3.2-3B-Instruct-q4f16_1-MLC"
    }

    var body: some View {
        VStack(alignment: .leading) {
            if (modelState.modelDownloadState == .finished) {
                NavigationLink(destination:
                    ChatView()
                    .environmentObject(chatState)
                    .onAppear {
                        modelState.startChat(chatState: chatState)
                    }
                ) {
                    HStack {
                        Text(modelState.modelConfig.displayName ?? modelState.modelConfig.modelID!)
                        Spacer()
                        if chatState.isCurrentModel(modelID: modelState.modelConfig.modelID!) {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.borderless)
            } else {
                Text(modelState.modelConfig.modelID!).opacity(0.5)
            }
            HStack{
                if modelState.modelDownloadState != .finished || isRemoving {
                    ProgressView(value: Double(modelState.progress) / Double(modelState.total))
                        .progressViewStyle(.linear)
                }
                // 优化下载按钮状态切换逻辑
                if (modelState.modelDownloadState == .paused) {
                    Button {
                        Task {
                            @MainActor in
                            modelState.handleStart()
                        }
                        
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    .buttonStyle(.borderless)
                    .disabled(modelState.modelDownloadState == .downloading)  // 防止重复点击
                } else if (modelState.modelDownloadState == .downloading) {
                    Button {
                           Task {
                               @MainActor in
                               modelState.modelDownloadState = .paused  // 立即更新UI状态
                           }
                       } label: {
                           Image(systemName: "stop.circle")
                       }
                       .buttonStyle(.borderless)
                       .disabled(modelState.modelDownloadState == .paused)  // 防止重复点击
                } else if (modelState.modelDownloadState == .failed) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }

                if isRemoving && !isFirstModel {
                    Button(role: .destructive) {
                        // 只有当模型下载完成时才显示确认对话框
                        if modelState.modelDownloadState == .finished {
                            isShowingDeletionConfirmation = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(modelState.modelDownloadState == .finished ? .red : .gray)
                    }
                    .disabled(modelState.modelDownloadState != .finished)
                    .confirmationDialog("Delete Model", isPresented: $isShowingDeletionConfirmation) {
                        Button("Clear model") {
                            modelState.handleClear()
                        }
                        Button("Cancel", role: .cancel) {
                            isShowingDeletionConfirmation = false
                        }
                    } message: {
                        Text("Are you sure you want to delete this model? You can re-download it later.")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
