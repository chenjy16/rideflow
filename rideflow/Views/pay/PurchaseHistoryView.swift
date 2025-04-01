import SwiftUI
import CoreData

struct PurchaseHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Purchase.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Purchase.purchaseDate, ascending: false)]
    ) private var purchases: FetchedResults<Purchase>
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            if purchases.isEmpty {
                Text("No purchase records")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(purchases, id: \.transactionId) { purchase in
                    PurchaseHistoryRow(purchase: purchase)
                }
            }
        }
        .navigationTitle("Purchase History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

// Purchase history row component
struct PurchaseHistoryRow: View {
    let purchase: Purchase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction ID: \(purchase.transactionId)")
                .font(.headline)
            Text("Product ID: \(purchase.productId)")
                .font(.subheadline)
            Text("Purchase Date: \(purchase.purchaseDate, style: .date)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
