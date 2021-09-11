//
//  ViewModel.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import Foundation
import Combine
import ActivityIndicator
import TennisAPI

class ViewModel : ObservableObject {
    
    @Published var showAlert : Bool = false
    @Published var alertTitle : String = ""
    @Published var alertMessage : String = ""
    
    @Published var isLoading : Bool = true

    let trackingIndicator = ActivityIndicator()
    var cancellables = Set<AnyCancellable>()

    
    init() {
        trackingIndicator.loading.assign(to: \.isLoading, on: self).store(in: &cancellables)
    }
    
    
    // General Error Handling
    func handleAPIRequest(with completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            if let err = error as? ErrorResponse {
                self.alertTitle = "Error"
                switch err {
                case .error(401, _,_,_):
                    UserManager.current.logout()
                    break
                case .error:
                    self.alertMessage = err.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    /// Handle all errors, callback for a specific function
    /// - Parameters:
    ///   - completion: The completition from the request
    ///   - errorCode: HTTP code to handle
    ///   - errorHandler: Callback function to handle error when encountered
    func handleAPIRequest(with completion: Subscribers.Completion<Error>, for errorCode: Int, do errorHandler: @escaping (ErrorResponse) -> Void) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            if let err = error as? ErrorResponse {
                self.alertTitle = "Error"
                switch err {
                case .error(errorCode, _, _, _):
                    errorHandler(err)
                    break
                case .error(401, _,_,_):
                    UserManager.current.logout()
                    break
                case .error:
                    self.alertMessage = err.localizedDescription
                    break
                }
                self.showAlert = true
            }
        }
    }
    
    /// Handle all errors, callback for a specific function
    /// - Parameters:
    ///   - completion: The completition from the request
    ///   - forMultiple: Closure to handle multiple errors
    func handleAPIRequest(with completion: Subscribers.Completion<Error>, forMultiple handle: @escaping (ErrorResponse) -> Void) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            if let err = error as? ErrorResponse {
                handle(err)
            }
        }
        
    }
    
    
    
    
}
