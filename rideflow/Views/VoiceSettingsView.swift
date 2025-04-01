import SwiftUI

struct VoiceSettingsView: View {
    @StateObject private var viewModel = VoiceSettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            // 基本设置
            Section(header: Text("Basic Settings")) {
                Toggle("Enable Voice Announcements", isOn: $viewModel.isVoiceEnabled)
                    .onChange(of: viewModel.isVoiceEnabled) { _ in
                        viewModel.saveSettings()
                    }
                
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.code) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .onChange(of: viewModel.selectedLanguage) { _ in
                    viewModel.saveSettings()
                    viewModel.previewVoice()
                }
                
                VStack {
                    HStack {
                        Text("Speech Rate")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.voiceRate))
                    }
                    
                    Slider(value: $viewModel.voiceRate, in: 0.1...1.0, step: 0.1)
                        .onChange(of: viewModel.voiceRate) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                VStack {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.voiceVolume))
                    }
                    
                    Slider(value: $viewModel.voiceVolume, in: 0.1...1.0, step: 0.1)
                        .onChange(of: viewModel.voiceVolume) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                Button("Test Voice") {
                    viewModel.previewVoice()
                }
            }
            
            // 播报内容设置
            Section(header: Text("Announcement Content")) {
                Toggle("Announce Speed", isOn: $viewModel.announceSpeed)
                    .onChange(of: viewModel.announceSpeed) { _ in
                        viewModel.saveSettings()
                    }
                
                Toggle("Announce Distance", isOn: $viewModel.announceDistance)
                    .onChange(of: viewModel.announceDistance) { _ in
                        viewModel.saveSettings()
                    }
                
                Toggle("Announce Time", isOn: $viewModel.announceTime)
                    .onChange(of: viewModel.announceTime) { _ in
                        viewModel.saveSettings()
                    }
                
                Toggle("Announce Calories", isOn: $viewModel.announceCalories)
                    .onChange(of: viewModel.announceCalories) { _ in
                        viewModel.saveSettings()
                    }
            }
            
            // 替换播报频率设置部分
            Section(header: Text("Time Interval Settings")) {
                Toggle("Announce Every Minute", isOn: $viewModel.announceEveryMinute)
                      .onChange(of: viewModel.announceEveryMinute) { _ in
                          viewModel.saveSettings()
                      }
            }
        }
        .navigationTitle("Voice Settings")
        .onAppear {
            viewModel.loadSettings()
        }
    }
}

struct LanguageOption {
    let name: String
    let code: String
}
