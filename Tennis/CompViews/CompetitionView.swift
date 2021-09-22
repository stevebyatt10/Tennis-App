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
    
    func reload() {
        getTable()
        getRecentMatches()
        getCompPlayers()
    }
    
    func getTable() {
        
        CompetitionsAPI.getCompTable(id: comp.id ?? 0)
            .trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { table in
                if let competitors = table.competitors {
                    self.competitors = competitors
                }
            }.store(in: &cancellables)
        
    }
    
    func getRecentMatches() {
        
        MatchesAPI.getCompMatches(id: comp.id!, limit: 3)
            .trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { MatchesResponse in
                if let matches = MatchesResponse.matches {
                    self.recentMatches = matches
                }
            }
            .store(in: &cancellables)
    }
    
    func addMatchAndSort(match: Match) {
        self.recentMatches.append(match)
        self.recentMatches.sort { this, other in
            
            return this.endDate ?? Date() > other.endDate ?? Date()
        }
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
            NavigationLink(destination: NavigationLazyView(CompPlayers(model: model))) {
                CompTable(model: model)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack {
                HStack(alignment: .bottom) {
                    Text("Recent Matches")
                        .font(.title)
                        .padding()
                    Spacer()
                    NavigationLink(destination: NavigationLazyView( MatchList(compModel: model) ) ) {
                       Text("view all")
                    }
                    .padding()
                }
                
                if model.recentMatches.isEmpty {
                    if model.isLoading {
                        ProgressView()
                    } else {
                        Text("No matches yet")
                    }
                } else {
                    ForEach(model.recentMatches, id: \.matchID) { match in
                        if match.endDate == nil {
                            NavigationLink(destination: NavigationLazyView(MatchScoring(match: match, compModel: model))) {
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
                    
                    Text("Only viewing the \(model.recentMatches.count) most recent matches, tap view all to see more.")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .navigationBarTitle(model.comp.name ?? "", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.reload()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    NavigationLazyView(NewMatch(comp: model.comp, players: model.players, compModel: model))
                } label: {
                    Label("New Match", systemImage: "plus")
                }
            }
        }
        
    }
    
}


struct CompPlayers : View {
    
    @ObservedObject var model : CompViewModel
    @State var showInvites = false
    
    
    var body: some View {
        Form {
            ForEach(model.players, id: \.id) { player in
                Text(player.fullName())
            }
        }
        .navigationBarTitle("Players", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInvites = true
                } label: {
                    Label("Invite", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showInvites) {
            InviteCompPlayers(players: model.players, compid: model.comp.id!)
        }
    }
}

struct InviteCompPlayers : View {
    
    @ObservedObject var model : InviteViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var count = 0
    let compID : Int
    
    init(players : [Player], compid : Int) {
        self.compID = compid
        model = InviteViewModel()
        // Filter current players in comp
        model.getAllPlayers { player in
            return !players.contains(player)
        }
    }
    var body: some View {
        NavigationView {
            Form {
                ForEach(model.players, id: \.player.id) { p in
                    Button {
                        if let id = p.player.id {
                            let sel = model.toggleSelectionForPlayer(with: id)
                            count += sel ? 1 : -1
                        }
                    } label: {
                        Label(p.player.fullName(), systemImage: p.selected ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    
                }
            }
            .navigationBarTitle("Invite Players", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        model.selectPlayers()
                        model.invitePlayersToComp(id: compID)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(count == 0)
                }
            }
        }
    }
}



struct CompTable : View {
    
    @ObservedObject var model : CompViewModel
    
    var body: some View {
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
            if model.competitors.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else {
                    Text("No results yet")
                }
                
            }
            else {
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
        }
        .roundedBackground()
    }
}

struct InlineMatchTitle : View {
    let match : Match
    var body: some View {
        VStack {
            HStack {
                if match.endDate == nil {
                    Image(systemName: "circle")
                        .foregroundColor(.red)
                    Text("Live")
                }
                else {
                    Text(match.getFormattedStartDate() ?? "")
                }
                Spacer()
            }
            .foregroundColor(.white)
            
            HStack(alignment: .center) {
                VStack {
                    Text(WinOrLoss(player: match.player1!))
                    Text(" \(match.player1!.firstName!) \(match.player1!.lastName!)")
                    Text("\(match.score!.player1!)")
                }
                Spacer()
                Text("VS")
                Spacer()
                VStack {
                    Text(WinOrLoss(player: match.player2!))
                    Text(" \(match.player2!.firstName!) \(match.player2!.lastName!)")
                    Text("\(match.score!.player2!)")
                    
                }
            }
            .roundedBackground()
        }
    }
    
    func WinOrLoss(player: Player) -> String{
        
        guard let winnerID = match.winnerID else {
            return ""
        }
        
        return winnerID == player.id ? "W" : "L"
        
    }
}
