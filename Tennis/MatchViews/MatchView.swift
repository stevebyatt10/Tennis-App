//
//  MatchView.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine

class MatchModel : ViewModel {
    @Published var match : Match
    @Published var p1Stats : PointStat?
    @Published var p2Stats : PointStat?
    
    
    init(match : Match) {
        self.match = match
        
        super.init()
        
        getStats()
    }
    
    func getStats(){
        MatchesAPI.getMatchStats(id: match.matchID!)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { [self] stats in
                p1Stats = stats.player1
                p2Stats = stats.player2
            }
            .store(in: &cancellables)
    }
    
}

struct MatchView: View {
    @ObservedObject var model : MatchModel
    init(match : Match) {
        self.model = MatchModel(match: match)
    }
    
    var body: some View {
        VStack {
            
            HStack(alignment: .bottom) {
                VStack {
                    Text(model.match.winnerID! == model.match.player1!.id ? "W" : "L")
                    Text(model.match.player1!.fullName())
                }
                Spacer()
                Text("VS")
                Spacer()
                VStack {
                    Text(model.match.winnerID! == model.match.player2!.id ? "W" : "L")
                    Text(model.match.player2!.fullName())
                }
            }
            .frame(height: 50)
            .padding()
            .background(Color("textfield"))
            .cornerRadius(4)
            .shadow(radius: 4, x: 0, y: 3)
            
            Text("Match stats")
            if let duration = model.match.getMatchDuration() {
                Text("Match duration \(duration)" )
            }
            
            statView(p1Stat: model.p1Stats?.aces, stat: "Aces", p2Stat: model.p2Stats?.aces)
            statView(p1Stat: model.p1Stats?.faults, stat: "Faults", p2Stat: model.p2Stats?.faults)
            statView(p1Stat: model.p1Stats?.doubleFaults, stat: "Double Faults", p2Stat: model.p2Stats?.doubleFaults)
            statView(p1Stat: model.p1Stats?.errors, stat: "Unforced Errors", p2Stat: model.p2Stats?.errors)
            statView(p1Stat: model.p1Stats?.lets, stat: "Lets", p2Stat: model.p2Stats?.lets)

            
        }
    }
    
    struct statView: View {
        
        let p1Stat : Int?
        let stat : String
        let p2Stat : Int?
        
        var body: some View {
            HStack {
                
                Text(String(p1Stat ?? 0))
                Spacer()
                Text(stat)
                Spacer()
                Text(String(p2Stat ?? 0))
            }
            .padding()
        }
    }
    
}
