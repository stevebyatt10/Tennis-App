//
//  CreateCompView.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine

struct PlayerSelect {
    var player : Player
    var selected : Bool
    
    init(player : Player, s : Bool = false) {
        self.player = player
        self.selected = s
    }
}

class InviteViewModel : ViewModel {
    
    @Published var players : [PlayerSelect] = []
    @Published var selectedPlayers : [Player] = []
    
    
    func toggleSelectionForPlayer(with id: Int) -> Bool {
        var index = 0
        for playerS in players {
            if playerS.player.id == id {
                break
            }
            index += 1
        }
        
        players[index].selected.toggle()
        return players[index].selected
    }
    
    func getSelectedCount() -> Int{
        return selectedPlayers.count
    }
    
    func removeItems(at offsets: IndexSet) {
        for index in offsets {
            _ = toggleSelectionForPlayer(with: selectedPlayers[index].id ?? -1)
        }
        selectedPlayers.remove(atOffsets: offsets)
    }
    
    func selectPlayers() {
        
        selectedPlayers = players.filter({ p in
            return p.selected
        }).map({ p in
            p.player
        })
    }
    
    func invitePlayersToComp(id : Int) {
        guard let pid = UserManager.current.playerId else {
            return
        }
        
        let ids = selectedPlayers.map({ p in
            return p.id!
        })
        
        CompetitionsAPI.invitePlayersToComp(id: id, invitesRequest: InvitesRequest(playerIDs: ids, fromID: pid))
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { _ in
                return
            }.store(in: &cancellables)
        
    }
    
    
    func getAllPlayers(playerFilter: @escaping (Player) throws -> Bool) {
        PlayerAPI.getPlayers()
            .trackActivity(trackingIndicator)
            .sink { completiton in
                self.handleAPIRequest(with: completiton)
            } receiveValue: { res in
                if let p = res.players {
                    do {
                        self.players = try p.filter(playerFilter).map({ player in
                            return PlayerSelect(player: player)
                        })
                    }
                    catch {
                        self.players = p.map({ player in
                            return PlayerSelect(player: player)
                        })
                    }
                    
                    
                }
            }
            .store(in: &cancellables)
    }
    
    
    
}

class CreateCompModel : ViewModel {
    
    @Published var compName = ""
    @Published var isPrivate = false
    
    @ObservedObject var invModel = InviteViewModel()
    
    override init() {
        super.init()
        
        invModel.getAllPlayers { player in
            return player.id! != UserManager.current.playerId!
        }
        
    }
    
    
    func createCompetition(onCreate : @escaping (Competition) -> Void) {
        guard let id = UserManager.current.playerId else {
            return
        }
        CompetitionsAPI.createComp(compName: compName, isPrivate: isPrivate, creatorId: id)
            .trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { comp in
                if let cID = comp.id {
                    self.invModel.invitePlayersToComp(id: cID)
                    onCreate(comp)
                }
            }
            .store(in: &cancellables)
        
        
    }
    
    
    
}

struct CreateCompView: View {
    
    @StateObject var model = CreateCompModel()
    @ObservedObject var compModel : CompsViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var showInviteView = false
    
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Competition Name", text: $model.compName)
                        .keyboardType(.default)
                        .padding()
                    
                    
                    Toggle("Private", isOn: $model.isPrivate)
                }
                
                Section {
                    Button(action: {
                        showInviteView = true
                    }) {
                        Label("Invite Players", systemImage: "person.badge.plus")
                    }
                    
                    ForEach(model.invModel.selectedPlayers, id: \.id) { p in
                        Text(p.firstName ?? "name")
                    }
                    .onDelete(perform: model.invModel.removeItems)
                    
                    
                }
                
                Section {
                    Button("Create"){
                        self.model.createCompetition() { comp in
                            var c = comp
                            c.playerCount = 1
                            self.compModel.comps.append(c)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            
        }
        .navigationBarTitle("Create", displayMode: .inline)
        .sheet(isPresented: $showInviteView) { InvitePlayersView(model: model)}
        
    }
}


struct InvitePlayersView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var model : CreateCompModel
    
    @State var startCount = 0
    @State var count = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    ForEach(model.invModel.players, id: \.player.id) { p in
                        Button {
                            if let id = p.player.id {
                                let sel = model.invModel.toggleSelectionForPlayer(with: id)
                                count += sel ? 1 : -1
                            }
                        } label: {
                            Label(p.player.fullName(), systemImage: p.selected ? "checkmark.circle.fill" : "checkmark.circle")
                        }
                        
                    }
                }
            }
            .navigationBarTitle("Select Players", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        model.invModel.selectPlayers()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(count == startCount)
                }
            }
            
        }
        .onAppear() {
            self.count = model.invModel.getSelectedCount()
            self.count = startCount
        }
        
    }
    
    
    
    
    
}
