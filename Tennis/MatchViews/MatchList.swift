//
//  MatchList.swift
//  MatchList
//
//  Created by Stephen Byatt on 22/9/21.
//

import SwiftUI
import TennisAPI
import Combine


class MatchListModel : ViewModel {
    @Published var comp : Competition
    @Published var matches = [Match]()
    
    init(comp: Competition) {
        self.comp = comp
        super.init()
        
        getMatches()
    }
    
    func getMatches() {
        MatchesAPI.getCompMatches(id: comp.id!).trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { MatchesResponse in
                self.matches = MatchesResponse.matches ?? []
            }
            .store(in: &cancellables)
        
    }
    
}

struct MatchList: View {
    
    @ObservedObject var model : MatchListModel
    @ObservedObject var compModel : CompViewModel
    
    init(compModel : CompViewModel) {
        model = MatchListModel(comp: compModel.comp)
        self.compModel = compModel
    }
    
    
    var body: some View {
        ScrollView {
            if model.matches.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else {
                    Text("No matches yet")
                }
            } else {
                ForEach(model.matches, id: \.matchID) { match in
                    if match.endDate == nil {
                        NavigationLink(destination: NavigationLazyView(MatchScoring(match: match, compModel: compModel))) {
                            InlineMatchTitle(match: match)
                        }
                        .padding(.horizontal)
                        
                    }
                    
                    else {
                        NavigationLink(destination: NavigationLazyView(MatchView(match: match))) {
                            InlineMatchTitle(match: match)
                        }
                        .padding(.horizontal)
                        
                    }
                }
            }
        }
        .navigationBarTitle("Matches")
        
    }
}

