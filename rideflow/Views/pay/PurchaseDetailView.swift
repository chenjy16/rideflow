import SwiftUI
import StoreKit

struct PurchaseDetailView: View {
    let product: Product
    let onPurchase: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Add AI model data, keeping only modelId and displayName
    private let aiModels = [
        AIModel(
            modelId: "gemma-2-2b-q4f16_1",
            displayName: "AI Model 1"
        ),
        AIModel(
            modelId: "Phi-3.5-mini-instruct-q4f16_1",
            displayName: "AI Model 2"
        ),
        AIModel(
            modelId: "Qwen2.5-1.5B-Instruct-q4f16_1",
            displayName: "AI Model 3"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(product.displayName)
                    .font(.title)
                    .bold()
                
                Text(product.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Add AI model list, displaying only modelId
                VStack(alignment: .leading, spacing: 16) {
                    Text("Included AI Models")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(aiModels) { model in
                        HStack {
                            Text(model.displayName)
                                .font(.subheadline)
                                .bold()
                            Spacer()
                            Text(model.modelId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                VStack(spacing: 12) {
                    Button(action: {
                        onPurchase()
                        dismiss()
                    }) {
                        Text("Purchase \(product.displayPrice)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Purchase Details")
    }
}

// Simplified AI model data structure, keeping only necessary fields
struct AIModel: Identifiable {
    let id = UUID()
    let modelId: String
    let displayName: String
}
