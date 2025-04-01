import SwiftUI

struct PurchaseStatusView: View {
    let isPurchased: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isPurchased ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(isPurchased ? .green : .red)
            Text(isPurchased ? "已购买" : "未购买")
                .font(.subheadline)
                .foregroundColor(isPurchased ? .green : .red)
        }
    }
}
