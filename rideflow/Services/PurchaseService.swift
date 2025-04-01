import StoreKit
import CoreData
import CoreDataStorage
import Combine
import SwiftUI
import Injected

// MARK: - Protocol
@MainActor
protocol PurchaseServiceType {
    var products: [Product] { get }
    var purchasedProductIDs: Set<String> { get }
    func purchase(_ product: Product) async throws
    func restorePurchases() async
    func isPurchased(productId: String) -> Bool
}

// MARK: - Implementation
@MainActor
class PurchaseService: ObservableObject, PurchaseServiceType, Service {
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    @Published private(set) var error: PurchaseError?
    
    @Published var alertMessage: String? // Remove private(set)
    
    private let storage: CoreDataStorage
    private let productIdentifiers = [
        "com.jianyuchen.toolapp.ride",
    ]

    private var updates: Task<Void, Never>?

    // MARK: - Service Protocol
    let shouldAutostart = true
    
    
    // 添加共享实例
    static let shared = PurchaseService()
    
    // 添加回调属性
    var onPurchaseCompleted: ((String) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    // 使用 weak self 避免循环引用
    private func setupObservers() {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshPurchases()
                }
            }
            .store(in: &cancellables)
    }
    
    

    // MARK: - Initialization
    init() {
        self.storage = StorageService.getStorage()
    }

    
    
    // MARK: - Service Lifecycle
    nonisolated func start() {
        Task { @MainActor in
            self.updates = observeTransactionUpdates()
            loadStoredPurchases()
            await loadProducts()
            // 添加启动时验证
            await verifyPurchases()
        }
    }
       
       nonisolated func stop() {
           Task { @MainActor in
               updates?.cancel()
               updates = nil
           }
       }
    
 
    // MARK: - Public Methods
    func purchase(_ product: Product) async throws {
        isLoading = true
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                await handlePurchase(verification)
            case .userCancelled:
                throw PurchaseError.userCancelled
            case .pending:
                throw PurchaseError.pending
            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            self.error = error as? PurchaseError ?? .unknown
            throw error
        }
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
       do {
           for await verification in await Transaction.currentEntitlements {
               await handlePurchase(verification)
           }
           await MainActor.run {
               alertMessage = "Restore purchases successful"
           }
       } catch {
           await MainActor.run {
               self.error = error as? PurchaseError ?? .unknown
               alertMessage = "Failed to restore purchases: \(self.error?.localizedDescription ?? "Unknown error")"
           }
       }
       isLoading = false
    }
    
    func isPurchased(productId: String) -> Bool {
        // 首先检查内存中的状态
         if purchasedProductIDs.contains(productId) {
             return true
         }
         // 然后检查本地数据库
         return storage.isPurchaseRecordExists(productId: productId)
    }
    
    // 修复 handlePurchase 方法
    private func handlePurchase(_ verification: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = verification else {
            return
        }
        
        await transaction.finish()
        await savePurchaseRecord(transaction)
        
        await MainActor.run {
            withAnimation {
                purchasedProductIDs.insert(transaction.productID)
                onPurchaseCompleted?(transaction.productID)
            }
        }
    }
    
    // 添加刷新购买记录的方法
   func refreshPurchases() async {
       await MainActor.run {
           purchasedProductIDs.removeAll()
       }
       loadStoredPurchases()
   }
    
    private func savePurchaseRecord(_ transaction: StoreKit.Transaction) async {
        await storage.update { context in
            // 检查记录是否已存在
            let request: NSFetchRequest<Purchase> = Purchase.fetchRequest()
            request.predicate = NSPredicate(format: "transactionId == %@", String(transaction.id))
            
            do {
                let count = try context.count(for: request)
                if count == 0 {
                    // 如果记录不存在，则创建新记录
                    _ = Purchase.create(
                        productId: transaction.productID,
                        transactionId: String(transaction.id),
                        context: context
                    )
                }
            } catch {
                print("Error checking existing purchase record: \(error)")
            }
        }
    }
    
    // 添加公开的加载产品方法
    func loadProducts() async {
        isLoading = true
        do {
            
            
            let loadedProducts = try await Product.products(for: productIdentifiers)
            await MainActor.run {
                self.products = loadedProducts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error as? PurchaseError ?? .unknown
                self.isLoading = false
            }
        }
    }
    
    private func loadStoredPurchases() {
        for productId in productIdentifiers {
            if isPurchased(productId: productId) {
                purchasedProductIDs.insert(productId)
            }
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                await handlePurchase(result)
            }
        }
    }
    

    // 添加验证购买记录的方法
    func verifyPurchases() async {
        isLoading = true
        
        // 清除当前内存中的购买状态
        await MainActor.run {
            purchasedProductIDs.removeAll()
        }
        
        // 从本地数据库加载购买记录
        loadStoredPurchases()
        
        // 与 App Store 验证
        do {
            var validProductIDs = Set<String>()
            
            for await verification in await Transaction.currentEntitlements {
                if case .verified(let transaction) = verification {
                    validProductIDs.insert(transaction.productID)
                }
            }
            
            // 更新内存中的状态，只保留有效的购买
            await MainActor.run {
                purchasedProductIDs = purchasedProductIDs.intersection(validProductIDs)
                
                // 如果发现无效的购买记录，清理数据库
                let invalidProductIDs = Set(productIdentifiers).subtracting(validProductIDs)
                if !invalidProductIDs.isEmpty {
                    Task {
                        await cleanupInvalidPurchases(invalidProductIDs)
                    }
                }
            }
        } catch {
            print("验证购买记录失败: \(error)")
        }
        
        isLoading = false
    }

    // 清理无效的购买记录
    private func cleanupInvalidPurchases(_ invalidProductIDs: Set<String>) async {
        for productId in invalidProductIDs {
            await storage.update { context in
                let request: NSFetchRequest<Purchase> = Purchase.fetchRequest()
                request.predicate = NSPredicate(format: "productId == %@", productId)
                
                do {
                    let purchases = try context.fetch(request)
                    for purchase in purchases {
                        context.delete(purchase)
                    }
                } catch {
                    print("清理无效购买记录失败: \(error)")
                }
            }
        }
    }

    
}




