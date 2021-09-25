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
    
    func reload() async {
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
                    self.addCompAfterInvite(compID: invite.comp!.id!)
                }
            }.store(in: &cancellables)
        
    }
    
    func addCompAfterInvite(compID : Int) {
        CompetitionsAPI.getComp(id: compID)
            .sink { completion in
                self.handleAPIRequest(with: completion)
            } receiveValue: { comp in
                self.comps.append(comp)
            }
            .store(in: &cancellables)
        
    }
    
}

struct CompsView: View {
    
    @StateObject var model = CompsViewModel()
    @State var showAlerts : Bool = false
    
    init() {
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        NavigationView {
            VStack {
                
                // Add and search buttons
                HStack {
                    NavigationLink(destination: CreateCompView(compModel: model)) {
                        Label("Create", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    
                    Button(action: {}) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                
                List() {
                    if model.comps.isEmpty {
                        HStack {
                            Spacer()
                            if model.isLoading {
                                ProgressView()
                            } else {
                                Text("No competitions")
                            }
                            Spacer()
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listStyle(.plain)
                    }
                    else {
                        ForEach(model.comps, id: \.id)  {comp in
                            NavigationLink(destination: NavigationLazyView(CompetitionView(comp: comp))) {
                                InlineCompTitle(comp: comp)
                            }
                            
                            .roundedBackground()
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await model.reload()
                }
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

struct InlineCompTitle: View {
    let comp : Competition
    var body: some View {
        HStack(alignment: .bottom) {
            Text(comp.formatPosition())
                .font(.largeTitle)
                .padding(.trailing)
                .frame(width: 80)
            
            Text(comp.name ?? "")
                .font(.title)
            
        }
        .frame(height: 50)
    }
    
}


struct CompsView_Previews: PreviewProvider {
    static var previews: some View {
        CompsView()
    }
}
