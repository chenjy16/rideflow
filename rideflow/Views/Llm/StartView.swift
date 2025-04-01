import SwiftUI

struct ThemeColors {
    let accent = "#A7C9E2"
    let primary = "#E1F5FE"
    let lightBlue = "#F0F9FF"
    let white = "#FFFFFF"
    let darkGray = "#4A4A4A"
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct StartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAdding: Bool = false
    @State private var isRemoving: Bool = false
    @State private var inputModelUrl: String = ""
    @State private var selectedTab: Int = 0
    @State private var isEnabled: Bool = true
    @State private var showPurchasePrompt: Bool = false
    
    // Integrate purchase service
    @StateObject private var purchaseService = PurchaseService.shared
    
    // Default model ID - Assume the first model is free
    private let defaultModelID = "Llama-3.2-3B-Instruct-q4f16_1-MLC"
    
    // Check if the model is the default model
    private func isDefaultModel(_ modelState: ModelState) -> Bool {
        return modelState.modelConfig.modelID == defaultModelID
    }
    
    // Check if the user has purchased premium features
    private var hasPurchasedPremium: Bool {
        // Replace with your actual product ID
        return purchaseService.isPurchased(productId: "com.jianyuchen.toolapp.ride")
    }
    
    private let themeColors = ThemeColors()

    var body: some View {
        ZStack {
            List {
                Section {
                    ForEach(appState.models) { modelState in
                        // Show based on purchase status and model type
                        if isDefaultModel(modelState) || hasPurchasedPremium {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                    .frame(width: 30)
                                
                                ModelView(isRemoving: $isRemoving)
                                    .environmentObject(modelState)
                                    .environmentObject(appState.chatState)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Add badge for premium models
                                if !isDefaultModel(modelState) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Show edit button only if premium is purchased
                    if hasPurchasedPremium {
                        if !isRemoving {
                            Button(action: { isRemoving = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Edit Models")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .padding(.top, 8)
                        } else {
                            Button(action: { isRemoving = false }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Done Editing")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        // Show purchase prompt for non-premium users
                        Button(action: { showPurchasePrompt = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                Text("Unlock All Models")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)
                    }
                }
                .listRowBackground(Color(hex: themeColors.lightBlue).opacity(0.5))
            }
            .listStyle(InsetGroupedListStyle())
            
            // Purchase prompt modal
            .sheet(isPresented: $showPurchasePrompt) {
                NavigationStack {
                    if let product = purchaseService.products.first(where: { $0.id == "com.jianyuchen.toolapp.ride" }) {
                        VStack(spacing: 20) {
                            Text("Unlock More Models")
                                .font(.title)
                                .bold()
                            
                            Text("Purchase the premium version to unlock all AI models and enjoy enhanced features.")
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button {
                                Task {
                                    do {
                                        try await purchaseService.purchase(product)
                                        showPurchasePrompt = false
                                    } catch {
                                        // Handle purchase error
                                        appState.alertMessage = "Purchase Failed: \(error.localizedDescription)"
                                        appState.alertDisplayed = true
                                    }
                                }
                            } label: {
                                Text("Buy \(product.displayPrice)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            Button("Restore Purchases") {
                                Task {
                                    await purchaseService.restorePurchases()
                                    showPurchasePrompt = false
                                }
                            }
                            .padding(.top)
                        }
                        .padding()
                    } else {
                        VStack {
                            Text("Loading product information...")
                            ProgressView()
                            
                            Button("Close") {
                                showPurchasePrompt = false
                            }
                            .padding(.top, 20)
                        }
                        .padding()
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .alert("Error", isPresented: $appState.alertDisplayed) {
            Button("OK") { }
        } message: {
            Text(appState.alertMessage)
        }
        .onAppear {
            if purchaseService.products.isEmpty {
                Task {
                    await purchaseService.loadProducts()
                }
            }
        }
    }
}
