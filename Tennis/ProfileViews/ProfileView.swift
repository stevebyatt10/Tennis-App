//
//  ProfileView.swift
//  ProfileView
//
//  Created by Stephen Byatt on 10/9/21.
//

import SwiftUI
import TennisAPI
import Combine

class ProfileModel : ViewModel {
    
    @Published var player = Player()
    
    override init() {
        super.init()
        
        guard let id = UserManager.current.playerId else {
            return
        }
        PlayerAPI.getPlayer(id: id)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { player in
                self.player = player
                UserManager.current.setAdmin(player: player)
            }
            .store(in: &cancellables)
        
    }
}

struct ProfileView: View {
    
    @ObservedObject var model = ProfileModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text(model.player.fullName())
                Button("Log Out") {
                    UserManager.current.logout()
                }
            }
            .navigationTitle("Profile")
            
            //        .toolbar {
            //            Button(action: {showAlerts.toggle()}) {
            //                Label("Alerts", systemImage:model.invites.count > 0 ? "bell.badge.fill" : "bell")
            //            }
            //        }
        }
    }
}
