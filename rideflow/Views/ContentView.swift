import SwiftUI
import Injected
import SplitView
import CoreDataStorage



extension AnyTransition {
    static var slideInOut: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .bottom)
        )
            .combined(with: .scale(scale: 0.5))
            .combined(with: .opacity)
    }
}

struct ContentView<Presenter: RootPresenting>: View {

    @ObservedObject var presenter: Presenter
    @Environment(\.managedObjectContext) var viewContext
    // 创建 AppState
     @StateObject private var appState = AppState()

    @State private var isHistoryPresented = false
    @State private var isImportPresented = false
    @State private var isExportPresented = false
    @State private var isPermissionPresented = false
    @State private var importTitle = ""
    
    // 添加标签选择状态
    @State private var selectedTab = 0

    @Injected private var gpxImport: GPXImporter
    @Injected private var locationPermissions: LocationPermissions
    
    @Injected private var storage: CoreDataStorage  // 添加 storage 注入
    
    


    var rideView: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                GeometryReader { geometry in
                    SplitView(
                        viewModel: self.presenter.viewModel.sliderViewModel,
                        controlView: { SliderControlView() },
                        topView: { MapView(viewModel: self.presenter.viewModel.mapViewModel) },
                        bottomView: {
                            VStack(spacing: 0) {
                                GaugesWithIndicatorView(viewModel: self.presenter.viewModel)
                                ActionButton(goViewModel: self.presenter.viewModel.goButtonViewModel,
                                             stopViewModel: self.presenter.viewModel.stopButtonViewModel) { intention in
                                                switch intention {
                                                case .startPause:
                                                    self.presenter.viewModel.startPauseRide()
                                                case .stop:
                                                    self.presenter.viewModel.stopRide()
                                                }
                                }
                                .frame(height: 96)
                                .padding([.bottom], 8)
                                Rectangle()
                                    .frame(height: geometry.safeAreaInsets.bottom)
                                    .foregroundColor(Color(UIColor.systemBackground))
                            }
                            .background(Color(UIColor.systemBackground))
                    })
                }
                self.menuButton
            }
            .blur(radius: self.isImportPresented ? 3 : 0)
            .opacity(self.isImportPresented ? 0.5 : 1.0)
            
            if self.isImportPresented {
                self.importView
                    .transition(.slideInOut)
            }
            if self.isPermissionPresented {
                self.notificationView
                    .transition(.slideInOut)
            }
        }
    }

    
    
    
    
    var menuButton: some View {
        Button(action: {
            self.isHistoryPresented.toggle()
        }, label: {
            Image(systemName: "line.horizontal.3")
        })
            .buttonStyle(MenuButtonStyle())
            .padding()
    }

    var importView: some View {
        GeometryReader { geometry in
            Group {
                VStack(spacing: 16) {
                    Text(Strings.import_gpx_message)
                        .bold()
                    Text(self.importTitle)
                    HStack {
                        Button(
                            action: { withAnimation { self.isImportPresented = false } },
                            label: { Text(Strings.no) }
                        )
                            .buttonStyle(AlertButtonStyle())
                            .foregroundColor(.red)
                        Button(
                            action: {
                                withAnimation {
                                    self.isImportPresented = false
                                }
                                self.gpxImport.save()
                        },
                            label: { Text(Strings.yes) }
                        )
                            .buttonStyle(AlertButtonStyle())
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(minWidth: 0, maxWidth: geometry.size.width, minHeight: 0, maxHeight: geometry.size.height / 2)
                .cornerRadius(18)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .padding(48)
            .clipped()
            .shadow(radius: 6)
        }
    }

    var notificationView: some View {
        GeometryReader { geometry in
            Group {
                Button(action: {
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil
                    )
                }) {
                    VStack {
                        Text(Strings.enable_location_title)
                            .font(.headline)
                            .foregroundColor(Color(UIColor.label))
                        Text(Strings.enable_location_details)
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .frame(width: geometry.size.width - 68*2, height: 70)
            .background(Color(UIColor.systemBackground))
            .transition(.slide)
            .offset(x: 68, y: 16)
        }
    }
    
    
    
    // 新增大模型视图
    var mlcView: some View {
        NavigationView {
            StartView()
                .navigationTitle("RideMind")
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)  // 注入 AppState
        }
    }
    
    
    // 新增大模型视图
    var settingView: some View {
        NavigationView {
            AboutView()
           .navigationTitle("Setting")
           .environment(\.managedObjectContext, viewContext)
           .environmentObject(appState)
        }
    }
    

    var body: some View {

        TabView(selection: $selectedTab) {
            rideView
                .tabItem {
                    Image(systemName: "bicycle")
                    Text("Speed Tracking")
                }
                .tag(0)
            
            // 新增统计分析标签
            RideInsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Insights")
                }
                .tag(1)
            
            mlcView
                .tabItem {
                    Image(systemName: "brain")
                    Text("Ride Mind")
                }
                .tag(2)
            
            settingView
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Setting")
                }
                .tag(3)
        }
     
        .sheet(isPresented: $isHistoryPresented) {
            HistoryView(viewModel: HistoryViewModel())
        }
        .onReceive(gpxImport.availableGPX) { gpx in
            self.importTitle = gpx.name ?? Strings.unnamed_ride
            withAnimation { self.isImportPresented = true }
        }.onReceive(locationPermissions.status) { status in
            // 确保在主线程更新UI
            DispatchQueue.main.async {
                switch status {
                case .denied, .restricted:
                    withAnimation { self.isPermissionPresented = true }
                default:
                    withAnimation { self.isPermissionPresented = false }
                }
            }
        }
        .environment(\.managedObjectContext, self.viewContext)
        .onAppear {
            // 初始化 AppState
            appState.loadAppConfigAndModels()
        }
        .environmentObject(appState)  // 注入到整个视图层级
        .edgesIgnoringSafeArea([.horizontal, .bottom])
    }
}
