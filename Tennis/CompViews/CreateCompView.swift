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

class CreateCompModel : ViewModel {
    
    @Published var players : [PlayerSelect] = []
    @Published var selectedPlayers : [Player] = []
    
    @Published var compName = ""
    @Published var isPrivate = false
    
    override init() {
        super.init()
        
        getAllPlayers()
        
    }
    
    func getAllPlayers() {
        PlayerAPI.getPlayers()
            .trackActivity(trackingIndicator)
            .sink { completiton in
                self.handleAPIRequest(with: completiton)
            } receiveValue: { res in
                if let p = res.players {
                    for player in p {
                        if player.id! == UserManager.current.playerId! {
                            continue
                        }
                        self.players.append(PlayerSelect(player: player))
                    }
                }
            }
            .store(in: &cancellables)
    }
    
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
    
    func selectPlayers() {
        
        selectedPlayers = players.filter({ p in
            return p.selected
        }).map({ p in
            p.player
        })
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
    
    func createCompetition() {
        guard let id = UserManager.current.playerId else {
            return
        }
        CompetitionsAPI.createComp(compName: compName, isPrivate: isPrivate, creatorId: id)
            .trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { comp in
                if let cID = comp.id {
                    self.invitePlayersToComp(id: cID)
                }
            }
            .store(in: &cancellables)
        
        
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
    
}

struct CreateCompView: View {
    
    @StateObject var model = CreateCompModel()
    
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
                    
                    ForEach(model.selectedPlayers, id: \.id) { p in
                        Text(p.firstName ?? "name")
                    }
                    .onDelete(perform: model.removeItems)
                    
                    
                }
                
                Section {
                    Button("Create"){
                        self.model.createCompetition()
                    }
                }
            }
            
        }
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
                        model.selectPlayers()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(count == startCount)
                }
            }
            
        }
        .onAppear() {
            self.count = model.getSelectedCount()
            self.count = startCount
        }
        
    }
    
    
    
    
    
}


struct CreateCompView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompView()
    }
}
