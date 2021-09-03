//
//  UserManager.swift
//  Tennis
//
//  Created by Stephen Byatt on 31/8/21.
//

import Foundation
import KeychainSwift
import TennisAPI
import Combine

final class UserManager {
    static let current = UserManager()
    private let keychain = KeychainSwift()
    private let nc = NotificationCenter.default
    var isLoggedIn = false
    var playerId : Int?
    
    private var cancellables = Set<AnyCancellable>()



    init() {
        if let token = keychain.get("Token"), let id = keychain.get("PlayerId") {
            login(token: token, id: Int(id)!)
        }
    }
    
    
    func login(token: String, id: Int) {
        playerId = id
        
        TennisAPI.customHeaders["Token"] = token
        keychain.set(token, forKey: "Token")
        keychain.set(String(id), forKey: "PlayerId")

        nc.post(name: Notification.Name("didLogIn"), object: nil)
        isLoggedIn = true
    }
    
    func logout(){
        guard let id = playerId else {
            return
        }
        AuthAPI.logout(id: id).sink { completion in
            switch completion {
            case .finished:
                print("completed")
            case .failure(let error):
                if let err = error as? ErrorResponse {
                    switch err {
                        case .error(401, _, _, _):
                            break
                        case .error:
                            print(err.localizedDescription)
                    }
                }
            }
        } receiveValue: { [self] _ in
            
            TennisAPI.customHeaders.removeValue(forKey: "Token")
            keychain.delete("Token")
            keychain.delete("PlayerId")
            nc.post(name: Notification.Name("didLogOut"), object: nil)
            isLoggedIn = false
        }
        .store(in: &cancellables)
    }
    

    
}
