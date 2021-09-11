//
//  AlertView.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine

struct AlertView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var model : CompsViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                ForEach(model.invites, id: \.self) { i in
                    HStack {
                        VStack {
                            Text("Competition: \(i.comp!.name!)")
                            Text("Invite from \(i.fromPlayer!.firstName!)")
                        }
                        Button {
                            self.model.manageInvite(invite: i, accept: true)
                        } label: {
                            Text("Accept")
                        }
                        .padding()
                        
                        Button {
                            self.model.manageInvite(invite: i, accept: false)
                        } label: {
                            Text("Decline")
                        }
                        .padding()
                        
                        
                        
                    }
                }
            }
            .navigationBarTitle("Alerts", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
        }
    }
}
