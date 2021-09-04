//
//  CompsView.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine

class CompsViewModel: ViewModel {
    @Published var comps : [Competition] = []
    @Published var invites : [Invite] = []
    
    override init() {
        super.init()
        
        getPlayerComps()
        getInvites()
    }
    
    func getPlayerComps(){
        guard let id  = UserManager.current.playerId else {
            return
        }
        CompetitionsAPI.getPlayerComps(id: id)
            .trackActivity(trackingIndicator)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { [self] response in
                print("got competitions")
                if let competitions = response.competitions {
                    comps = competitions
                }
            }
            .store(in: &cancellables)
    }
    
    func getInvites() {
        guard let id  = UserManager.current.playerId else {
            return
        }
        
        PlayerAPI.getPendingInvites(id: id)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { res in
                if let invites = res.invites {
                    self.invites = invites
                }
            }
            .store(in: &cancellables)

    }
    
    func manageInvite(invite: Invite, accept: Bool) {
        guard let id  = UserManager.current.playerId else {
            return
        }
        
        PlayerAPI.respondToInvite(id: id, compID: invite.comp!.id!, accept: accept)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { _ in
                self.invites.removeAll { inv in
                    return invite.comp?.id == inv.comp?.id
                }
                
                if accept {
                    self.comps.append(invite.comp!)
                }
            }.store(in: &cancellables)

    }
    
}

struct CompsView: View {
    
    @StateObject var model = CompsViewModel()
    @State var showAlerts : Bool = false
    

    
    var body: some View {
        NavigationView {
            ScrollView {
                
                HStack {
                    NavigationLink(destination: CreateCompView()) {
                        Label("Create", systemImage: "plus")
                    }
                    .padding()
                    
                    Button(action: {}) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .padding()
                }
                
                if model.isLoading {
                    ProgressView()
                }
                
                ForEach(model.comps, id: \.id) { comp in
                    NavigationLink(destination: NavigationLazyView(CompetitionView(comp: comp))) {
                        HStack(alignment: .bottom) {
                            Text(comp.name ?? "")
                            Spacer()
                            Text("3 Players")
                        }
                        .frame(height: 50)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(4)
                        .shadow(radius: 4, x: 0, y: 3)

                    }
                    .padding()

                }
                Spacer()
            }
            .navigationTitle("Comps")
            .toolbar {
                Button(action: {showAlerts.toggle()}) {
                    Label("Alerts", systemImage:model.invites.count > 0 ? "bell.badge.fill" : "bell")
                }
            }
            .sheet(isPresented: $showAlerts) { AlertView(model: model) }
        }
        
    }
}

struct CompsView_Previews: PreviewProvider {
    static var previews: some View {
        CompsView()
    }
}
