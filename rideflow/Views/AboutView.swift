import SwiftUI
import StoreKit
import CoreDataStorage

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    @State private var showingPurchaseHistory = false
    
    var body: some View {
        NavigationStack {
            List {
                // App info section
                appInfoSection
                
                // Voice settings section
                voiceSettingsSection
                
                // Action buttons section
                actionButtonsSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPurchaseHistory) {
                NavigationStack {
                    PurchaseHistoryView()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var appInfoSection: some View {
        Section(header: Text("App Info")) {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(buildNumber)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var voiceSettingsSection: some View {
        Section(header: Text("Voice Announcements")) {
            NavigationLink(destination: VoiceSettingsView()) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("Voice Settings")
                }
            }
        }
    }
    
    
    private var actionButtonsSection: some View {
        Section {
            Button("Purchase History") {
                showingPurchaseHistory = true
            }
        }
    }
}
