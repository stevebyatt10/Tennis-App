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
    var cancellables = Set<AnyCancellable>()
    var isLoading : Bool = true
    let trackingIndicator = ActivityIndicator()

    
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
                    switch err {
                        case .error:
                            print(err)
                    }
                }
                break
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
                    switch err {
                    case .error(errorCode, _, _, _):
                        errorHandler(err)
                    case .error:
                        print(err)
                    }
                }
                break
        }
    }
    

}
