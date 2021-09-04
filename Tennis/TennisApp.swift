//
//  TennisApp.swift
//  Tennis
//
//  Created by Stephen Byatt on 30/8/21.
//

import SwiftUI
import TennisAPI

class AppModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var loading = true
    
    init() {
        TennisAPI.basePath = "http://10.0.0.32:8080"
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(didLogIn), name: Notification.Name("didLogIn"), object: nil)
        nc.addObserver(self, selector: #selector(didLogOut), name: Notification.Name("didLogOut"), object: nil)
        
        isLoggedIn = UserManager.current.isLoggedIn
        
        loading = false
    }
    
    
    @objc func didLogIn() {
        isLoggedIn = true
    }
    
    @objc func didLogOut() {
        isLoggedIn = false
    }
}


class TennisAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // ...
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = TennisSceneDelegate.self
        return sceneConfig
    }
    
}

class TennisSceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneWillEnterForeground(_ scene: UIScene) {
        // ...
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // ...
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // ...
    }
    
}


@main
struct TennisApp: App {
    @UIApplicationDelegateAdaptor var delegate: TennisAppDelegate
    @StateObject var model = AppModel()
    var body: some Scene {
        WindowGroup {
            
            if model.loading {
                ProgressView()
            }
            else {
                if !model.isLoggedIn {
                    NavigationView {
                        LoginView()
                    }
                }
                else {
                    TabView {
                        CompsView()
                            .tabItem {
                                Image(systemName: "crown")
                                Text("Comps")
                            }
                        Button("Log Out") {
                            UserManager.current.logout()
                        }
                            .tabItem {
                                Image(systemName: "person")
                                Text("Profile")
                            }
                    }
                }
            }
            
        }
        
        
    }
}
