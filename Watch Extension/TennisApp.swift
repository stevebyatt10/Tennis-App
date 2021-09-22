//
//  TennisApp.swift
//  Watch Extension
//
//  Created by Stephen Byatt on 13/9/21.
//

import SwiftUI

@main
struct TennisApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
