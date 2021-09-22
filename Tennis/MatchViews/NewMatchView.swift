//
//  NewMatchView.swift
//  NewMatchView
//
//  Created by Stephen Byatt on 9/9/21.
//

import SwiftUI
import TennisAPI
import Combine

class NewMatchModel : ViewModel {
    
    @ObservedObject var compModel : CompViewModel
    @Published var comp : Competition
    
    @Published var players = [Player]()
    @Published var player1 : Player?
    @Published var player2 : Player?
    @Published var playersSelected : Bool = false
    
    @Published var matchCreated : Bool = false
    @Published var match = Match()
    @Published var score = ScoreResponse()
    @Published var currentServer = Player()
 
    @Published var player1Score = 0
    @Published var player2Score = 0
    
    
    init(comp : Competition, players : [Player], compModel : CompViewModel) {
        self.comp = comp
        self.compModel = compModel
        super.init()
        
        self.players = players
        
        // removing current player from the list
        //        for player in players {
        //            if player.id == UserManager.current.playerId! {
        //                player1 = player
        //                continue
        //            }
        //
        //            self.players.append(player)
        //        }
    }
    
    
    func getLatestPoint() {
        
        MatchesAPI.getMatchLatestPoint(id: match.matchID!)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { ScoreResponse in
                if ScoreResponse.newServer! == self.player1?.id! {
                    self.currentServer = self.player1!
                }
                else {
                    self.currentServer = self.player2!
                }
                self.score = ScoreResponse
            }
            .store(in: &cancellables)
    }
    
    
    func createMatch(server : Player, receiver : Player, points: Int, winBy: Int) {
        MatchesAPI.newCompMatch(id: comp.id!, serverID: server.id!, receiverID: receiver.id!, startDate: Date(), numPoints: points, winBy: winBy)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { NewMatch in
                print(NewMatch)
                if let match = NewMatch.match, let point = NewMatch.newPoint {
                    self.match = match
                    self.score = point
                    self.currentServer = server
                    self.matchCreated = true
                }
            }
            .store(in: &cancellables)
    }
    
    func updateScore(pointWinner : Int, fauts: Int?, lets: Int?, ace : Bool?, error : Bool?, gameOver: @escaping () -> Void) {
        MatchesAPI.scoreMatch(id: match.matchID!, pointNum: score.pointNum!, winnerID: pointWinner, faults: fauts, lets: lets, ace: ace, unforcedError: error)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { ScoreResponse in
                
                // Game is over
                if ScoreResponse.pointNum == nil {
                    print("game over")
                    gameOver()
                    return
                }
                
                
                // New game, server alternates
                if let sID = ScoreResponse.newServer {
                    if sID == self.player1!.id! {
                        self.currentServer = self.player1!
                    }
                    else {
                        self.currentServer = self.player2!
                    }
                }
                
                self.score = ScoreResponse
            }
            .store(in: &cancellables)
        
    }
    
    func undoPoint(undid: @escaping (PointStats) -> Void) {
        MatchesAPI.deleteMatchLatestPoint(id: match.matchID!).sink { completion in
            self.handleAPIRequest(with: completion)
        } receiveValue: { Point in
            if Point.winnerID == self.player1?.id {
                self.player1Score -= 1
            }
            else {
                self.player2Score -= 1
            }
            
            self.score.pointNum = Point.number
            self.score.newServer = Point.serverID
            
            if Point.serverID == self.player1?.id! {
                self.currentServer = self.player1!
            }
            else {
                self.currentServer = self.player2!
            }
            
            undid(Point.stats!)
        }
        .store(in: &cancellables)

    }
    
}

struct NewMatch: View {
    
    @ObservedObject var model : NewMatchModel
    
    init(comp : Competition, players : [Player], compModel : CompViewModel) {
        self.model = NewMatchModel(comp: comp, players: players, compModel: compModel)
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
    
    @State var toggleAlert = false
    
    init(model : NewMatchModel) {
        self.model = model
    }
    
    init(match : Match, compModel: CompViewModel) {
        self.model = NewMatchModel(comp: compModel.comp, players: [], compModel: compModel)
        self.model.match = match
        self.model.player1 = match.player1
        self.model.player2 = match.player2
        
        self.model.player1Score = match.score!.player1!
        self.model.player2Score = match.score!.player2!
        
        self.model.getLatestPoint()

    }
    
    
    var body: some View {
        VStack {
            
            HStack {
                VStack {
                    Text(model.player1!.fullName())
                    Text("\(model.player1Score)")
                    if model.currentServer.id == model.player1!.id! {
                        Label("Serving", systemImage: "largecircle.fill.circle")
                    }
                }
                
                Spacer()
                Text("VS")
                Spacer()
                VStack {
                    Text(model.player2!.fullName())
                    Text("\(model.player2Score)")
                    if model.currentServer.id == model.player2!.id! {
                        Label("Serving", systemImage: "largecircle.fill.circle")
                    }
                }
                
                
            }
            .padding()
            .background(Color("secondbg"))
            .cornerRadius(8)
            .shadow(radius: 4, x: 0, y: 3)
            
            VStack {
                
                Stepper(value: $faults, in: 0...2) {
                    Text("Faults \(faults)")
                }
                .onChange(of: faults) { _ in
                    if faults > 1 {
                        // Set recevier to winner
                        if model.currentServer.id == model.player1!.id! {
                            winnerID = model.player2!.id!
                        }
                        else {
                            winnerID = model.player1!.id!
                        }
                        error = false
                        ace = false
                    }
                }
                Stepper(value: $lets, in: 0...2) {
                    Text("Lets \(lets)")
                }
                .disabled(faults > 1)
                
                Toggle("Ace", isOn: $ace)
                    .onChange(of: ace) { _ in
                        if ace {
                            error = false
                            // Set server to winner
                            if model.currentServer.id == model.player1!.id! {
                                winnerID = model.player1!.id!
                            }
                            else {
                                winnerID = model.player2!.id!
                            }
                        }
                    }
                    .disabled(faults > 1)
                
                
                Toggle("Error", isOn: $error)
                    .onChange(of: error) { _ in
                        if error {
                            ace = false
                        }
                    }
                    .disabled(faults > 1)
                
                
                HStack {
                    Button(action: {winnerID = model.player1!.id!}) {
                        VStack {
                            Text(model.player1!.fullName())
                            Image(systemName: winnerID == model.player1!.id! ? "largecircle.fill.circle" : "circle")
                        }
                    }
                    Spacer()
                    Text("Point Winner")
                    Spacer()
                    Button(action: {winnerID = model.player2!.id!}) {
                        VStack {
                            Text(model.player2!.fullName())
                            Image(systemName: winnerID == model.player2!.id! ? "largecircle.fill.circle" : "circle")
                        }
                    }
                    
                }
                .disabled(ace || faults > 1)
                .padding()
                
                
                Button {
                    scorePoint()
                } label: {
                    Text("Score point")
                }
                .disabled(winnerID == nil)
                
            }
            .padding()
            .background(Color("secondbg"))
            .cornerRadius(8)
            .shadow(radius: 4, x: 0, y: 3)
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {toggleAlert.toggle()}) {
                    Label("Undo", systemImage: "arrowshape.turn.up.left")
                }
                .disabled(model.score.pointNum ?? 0 <= 1)
            }
            
        }
        .alert("Undo point", isPresented: $toggleAlert) {
            Button("Undo", role: .destructive) {
                model.undoPoint { stats in
                    self.faults = stats.faults ?? 0
                    self.error = stats.error ?? false
                    self.lets = stats.lets ?? 0
                    self.ace = stats.ace ?? false
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        
    }
    
    func scorePoint() {
        model.updateScore(pointWinner: winnerID!, fauts: faults, lets: lets, ace: ace, error: error, gameOver: onGameEnded)
        error = false
        ace = false
        faults = 0
        lets = 0
        
        if model.player1!.id! == winnerID {
            model.player1Score += 1
        } else {
            model.player2Score += 1
            
        }
        
        winnerID = nil

    }
    
    func onGameEnded() {
        MatchesAPI.getMatch(id: model.match.matchID!).sink { completion in
            self.model.handleAPIRequest(with: completion)
        } receiveValue: { Match in
            self.model.compModel.reload()
            self.presentationMode.wrappedValue.dismiss()
        }
        .store(in: &model.cancellables)
        
    }
}


struct MatchSetup : View {
    @ObservedObject var model : NewMatchModel
    
    @State var currentServing : Bool = true
    @State var points : Int = 5
    @State var pointsToWinBy : Int = 2

    
    var body: some View {
        ScrollView {
            if !model.playersSelected {
                Text("Select Players")
                    .font(.largeTitle)
                    .padding()
                
                ForEach(model.players, id: \.id) { player in
                    Button(action: {
                        if player.id == model.player1?.id {
                            model.player1 = nil
                        }
                        else if player.id == model.player2?.id{
                            model.player2 = nil
                        }
                        else {
                            // Player 1 not yet set
                            if model.player1 == nil {
                                model.player1 = player
                            }
                            // Player 2 not yet set
                            else if model.player2 == nil {
                                model.player2 = player
                            }
                        }
                    }) {
                        HStack {
                            Text(player.fullName())
                                .padding()
                            if player.id == model.player1?.id {
                                Text("P1")
                            }
                            else if player.id == model.player2?.id{
                                Text("P2")
                            }
                        }
                    }
                }
                Button("Ready") {
                    model.playersSelected = true
                }
                .disabled(model.player1 == nil || model.player2 == nil)
            } else {
                VStack {
                    HStack {
                        Text(model.player1!.fullName())
                        Spacer()
                        Text("VS")
                        Spacer()
                        Text(model.player2!.fullName())
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
                    
                    
                    
                    Stepper(value: $points, in: 2...10) {
                        Text("\(points) Points")
                    }
                    Stepper(value: $pointsToWinBy, in: 0...10) {
                        Text("\(pointsToWinBy) Points to win by")
                    }
                    
                    Button {
                        let server = currentServing ? self.model.player1 : self.model.player2
                        let receiver = !currentServing ? self.model.player1 : self.model.player2
                        self.model.createMatch(server: server!, receiver: receiver!, points: points, winBy: pointsToWinBy)
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
