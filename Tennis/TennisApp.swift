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


@main
struct TennisApp: App {
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
                    Button("Log out") {
                        UserManager.current.logout()
                    }
                }
            }
            
        }
    }
}
