import UIKit
import Combine
import CoreData
import Injected
import CoreDataStorage
import StoreKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
       
    private var cancellable = Set<AnyCancellable>()

       
    private(set) lazy var dependencies: Dependencies = {
        Dependencies {
            Dependency { StorageService.shared }
            Dependency { StorageService.getStorage() as CoreDataStorage }
            Dependency { LocationPermissions() }
            Dependency { LocationService() }
            Dependency { VoiceService.shared }
            Dependency { RideService() }
            Dependency { GPXImporter() }
            Dependency { GPXExporter() }
            Dependency { PurchaseService() }
        }
    }()
  
    
    

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

         // 启动购买服务
         PurchaseService.shared.start()
        // 初始化语音服务
         _ = VoiceService.shared
         _ = VoiceEventManager.shared

        return true
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 计算后台时间
        let timeInBackground = Date.timeIntervalSinceReferenceDate - backgroundTimestamp
        
        // 发送自定义通知
        NotificationCenter.default.post(
            name: Notification.Name("VoiceServiceDidEnterForeground"),
            object: timeInBackground
        )
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 记录进入后台的时间
        backgroundTimestamp = Date.timeIntervalSinceReferenceDate
    }

    // 添加时间戳属性
    private var backgroundTimestamp: TimeInterval = 0

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
