//
//  CompetitionView.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine


class CompViewModel : ViewModel {
    @Published var comp : Competition
    @Published var competitors = [Competitor]()
    @Published var recentMatches = [Match]()
    @Published var players = [Player]()
    
    
    init(comp: Competition) {
        self.comp = comp
        
        super.init()
        
        getTable()
        getRecentMatches()
        getCompPlayers()
    }
    
    func getTable() {
        
        CompetitionsAPI.getCompTable(id: comp.id ?? 0)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { table in
                if let competitors = table.competitors {
                    self.competitors = competitors
                }
            }.store(in: &cancellables)
        
    }
    
    func getRecentMatches() {
        
        MatchesAPI.getCompMatches(id: comp.id!)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { MatchesResponse in
                if let matches = MatchesResponse.matches {
                    self.recentMatches = matches
                }
            }
            .store(in: &cancellables)
    }
    
    
    func getCompPlayers() {
        CompetitionsAPI.getCompPlayers(id: comp.id!)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { PlayersResponse in
                if let players = PlayersResponse.players {
                    self.players = players
                }
            }
            .store(in: &cancellables)
        
    }
    
}

struct CompetitionView: View {
    
    @ObservedObject var model : CompViewModel
    init(comp : Competition) {
        self.model = CompViewModel(comp: comp)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    Text("Player")
                        .frame(width: 120)
                    
                    Text("Played")
                        .frame(width: 60)
                    
                    Text("Wins")
                        .frame(width: 60)
                    
                    Text("Losses")
                        .frame(width: 60)
                    
                }
                ForEach(model.competitors, id: \.player?.id) { competitor in
                    HStack {
                        Text("\(competitor.player!.firstName!) \(competitor.player!.lastName!)")
                            .frame(width: 120)
                        
                        Text("\(competitor.played!)")
                            .frame(width: 60)
                        
                        Text("\(competitor.wins!)")
                            .frame(width: 60)
                        
                        Text("\(competitor.losses!)")
                            .frame(width: 60)
                        
                    }
                    
                }
            }
            .padding(.bottom)
            
            
            NavigationLink(destination: NavigationLazyView(NewMatch(comp: model.comp, players: model.players))) {
                Text("New Match")
                    .padding()
            }
            
            
            VStack {
                HStack {
                    Text("Most recent matches")
                        .padding()
                    Spacer()
                    Button("view all") {
                        
                    }
                    .padding()
                }
                
                ForEach(model.recentMatches, id: \.matchID) { match in
                    HStack {
                        Text(match.getFormattedStartDate() ?? "")
                        Spacer()
                    }
                    .padding()
                    
                    NavigationLink(destination: NavigationLazyView(MatchView(match: match))) {
                        
                        HStack(alignment: .bottom) {
                            VStack {
                                Text(match.winnerID! == match.player1!.id ? "W" : "L")
                                Text(" \(match.player1!.firstName!) \(match.player1!.lastName!)")
                            }
                            Spacer()
                            Text("VS")
                            Spacer()
                            VStack {
                                Text(match.winnerID! == match.player2!.id ? "W" : "L")
                                Text(" \(match.player2!.firstName!) \(match.player2!.lastName!)")
                            }
                        }
                        .frame(height: 50)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(4)
                        .shadow(radius: 4, x: 0, y: 3)
                        
                    }
                    .padding()
                }
            }
            .padding(.top)
        }
        .navigationBarTitle(model.comp.name ?? "", displayMode: .inline)
        
    }
}



class NewMatchModel : ViewModel {
    
    @Published var comp : Competition
    
    @Published var players = [Player]()
    @Published var currentPlayer = Player()
    @Published var opposition = Player()
    @Published var playerSelected : Bool = false
    
    @Published var matchCreated : Bool = false
    @Published var match = Match()
    @Published var score = ScoreResponse()
    @Published var currentServer = Player()
    
    init(comp : Competition, players : [Player]) {
        self.comp = comp
        super.init()
        
        for player in players {
            if player.id == UserManager.current.playerId! {
                currentPlayer = player
                continue
            }
            
            
            self.players.append(player)
            
        }
    }
    
    func createMatch(server : Player, receiver : Player, sets :Int, games: Int, points: Int) {
        
        MatchesAPI.newCompMatch(id: comp.id!, serverID: server.id!, receiverID: receiver.id!, startDate: Date(), numSets: sets, numGames: games, numPoints: points)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { NewMatch in
                print(NewMatch)
                if let match = NewMatch.match, let score = NewMatch.newIDs {
                    self.match = match
                    self.score = score
                    self.currentServer = server
                    self.matchCreated = true
                }
            }
            .store(in: &cancellables)
        
    }
    
    func updateScore(pointWinner : Int, fauts: Int?, lets: Int?, ace : Bool?, error : Bool?, gameOver: @escaping () -> Void) {
        MatchesAPI.scoreMatch(id: match.matchID!, pointNum: score.pointNum!, gameID: score.gameID!, setID: score.setID!, winnerID: pointWinner, faults: fauts, lets: lets, ace: ace, unforcedError: error)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { ScoreResponse in
                
                // Game is over
                if ScoreResponse.gameID == nil {
                    print("game over")
                    gameOver()
                    return
                }
                
                // New game, server alternates
                if ScoreResponse.gameID != self.score.gameID {
                    if self.currentServer.id! == self.currentPlayer.id! {
                        self.currentServer = self.opposition
                    }
                    else {
                        self.currentServer = self.currentPlayer
                    }
                }

                self.score = ScoreResponse
            }
            .store(in: &cancellables)
        
    }
    
}

struct NewMatch: View {
    
    @ObservedObject var model : NewMatchModel
    
    init(comp : Competition, players : [Player]) {
        self.model = NewMatchModel(comp: comp, players: players)
    }
    
    var body: some View {
        if model.matchCreated {
            MatchScoring(model: model)
        } else {
            MatchSetup(model: model)
        }
    }
}

struct MatchScoring : View {
    @ObservedObject var model : NewMatchModel
    @Environment(\.presentationMode) var presentationMode
    
    @State var faults = 0
    @State var ace = false
    @State var error = false
    @State var lets = 0
    @State var winnerID : Int?
    
    
    var body: some View {
        VStack {
            Text("match id \(self.model.match.matchID!) set id \(self.model.score.setID!) game id \(self.model.score.gameID!) point id \(self.model.score.pointNum!)")
            
            Text("Serving \(model.currentServer.fullName())")
            Stepper(value: $faults, in: 0...2) {
                Text("Faults \(faults)")
            }
            Stepper(value: $lets, in: 0...2) {
                Text("Lets \(lets)")
            }
            Toggle("Ace", isOn: $ace)
                .onChange(of: error) { _ in
                    if error {
                        ace = false
                    }
                }
            
            Toggle("Error", isOn: $error)
                .onChange(of: ace) { _ in
                    if ace {
                        error = false
                    }
                }
            
            HStack {
                Button(action: {winnerID = model.currentPlayer.id!}) {
                    VStack {
                        Text(model.currentPlayer.fullName())
                        Image(systemName: winnerID == model.currentPlayer.id! ? "largecircle.fill.circle" : "circle")
                    }
                }
                Spacer()
                Text("Point Winner")
                Spacer()
                Button(action: {winnerID = model.opposition.id!}) {
                    VStack {
                        Text(model.opposition.fullName())
                        Image(systemName: winnerID == model.opposition.id! ? "largecircle.fill.circle" : "circle")
                    }
                }
                
            }
            .padding()
            
            
            Button {
                model.updateScore(pointWinner: winnerID!, fauts: faults, lets: lets, ace: ace, error: error) {
                    presentationMode.wrappedValue.dismiss()
                }
                error = false
                ace = false
                winnerID = nil
            } label: {
                Text("Score point")
            }
            .disabled(winnerID == nil)
            
            
            
        }
    }
}


struct MatchSetup : View {
    @ObservedObject var model : NewMatchModel
    
    @State var currentServing : Bool = true
    @State var sets : Int = 1
    @State var games : Int = 3
    @State var points : Int = 4
    @State var tradPointName : Bool = true
    
    
    var body: some View {
        ScrollView {
            if !model.playerSelected {
                Text("Select Oponent")
                    .font(.largeTitle)
                    .padding()
                
                ForEach(model.players, id: \.id) { player in
                    Button(action: {
                        model.opposition = player
                        model.playerSelected = true
                    }) {
                        Text(player.fullName())
                            .padding()
                    }
                }
            } else {
                VStack {
                    HStack {
                        Text(model.currentPlayer.fullName())
                        Spacer()
                        Text("VS")
                        Spacer()
                        Text(model.opposition.fullName())
                    }
                    .padding()
                    
                    
                    HStack {
                        Button(action: {currentServing.toggle()}) {
                            Image(systemName: currentServing ? "largecircle.fill.circle" : "circle")
                        }
                        Spacer()
                        Text("Server")
                        Spacer()
                        Button(action: {currentServing.toggle()}) {
                            Image(systemName: !currentServing ? "largecircle.fill.circle" : "circle")
                        }                    }
                    .padding()
                    
                    
                    
                    Stepper(value: $sets, in: 1...3) {
                        Text("\(sets) Sets")
                    }
                    Stepper(value: $games, in: 1...3) {
                        Text("\(games) Games")
                    }
                    Stepper(value: $points, in: 1...10) {
                        Text("\(points) Points")
                    }
                    
                    Button {
                        let server = currentServing ? self.model.currentPlayer : self.model.opposition
                        let receiver = !currentServing ? self.model.currentPlayer : self.model.opposition
                        self.model.createMatch(server: server, receiver: receiver, sets: sets, games: games, points: points)
                    } label: {
                        Text("Start Match")
                    }
                    
                }
                .padding()
            }
        }
        .navigationBarTitle("New Match", displayMode: .inline)
    }
    
}
