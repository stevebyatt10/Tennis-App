//
//  SignUpView.swift
//  Tennis
//
//  Created by Stephen Byatt on 31/8/21.
//

import SwiftUI
import KeychainSwift
import TennisAPI
import Combine

class SignUpModel: ViewModel {
    @Published var email = ""
    @Published var password = ""
    @Published var confPassword = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var loading = false
    
    
    func signUp() {
        if email.isEmpty || password.isEmpty || firstName.isEmpty {
            return
        }
        if password != confPassword {
            return
        }
        
        loading = true
        defer { loading = false }
        AuthAPI.registerPlayer(firstName: firstName, lastName: lastName, email: email, password: password)
            .sink { completion in
                print(completion)
            } receiveValue: { res in
                if let token = res.token, let id = res.playerId {
                    UserManager.current.login(token: token, id: id)
                }
            }
            .store(in: &cancellables)
    }
}

struct SignUpView: View {
    @StateObject var model = SignUpModel()
    @Environment(\.colorScheme) var currentColorScheme
    
    var body: some View {
        ZStack {
            Color("background")
                .ignoresSafeArea(.all)
            ScrollView {
                VStack {
                    HStack{
                        Text("TENNIS")
                            .font(.largeTitle)
                            .foregroundColor(Color("textfield"))
                            .flipColorScheme(currentColorScheme)
                            .padding()
                        
                        Image("tennislogo")
                            .resizable()
                            .frame(width: 106, height: 91, alignment: .center)
                            .padding()
                        
                    }
                    TextField("First Name", text: $model.firstName)
                        .keyboardType(.default)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(5)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.bottom)
                    
                    TextField("Last Name", text: $model.lastName)
                        .keyboardType(.default)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(5)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.bottom)
                    
                    TextField("Email", text: $model.email)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(5)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.bottom)
                    
                    SecureField("Password", text: $model.password)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(10)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.bottom)
                    
                    SecureField("Confirm Password", text: $model.confPassword)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(10)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.bottom)
                    
                    
                    
                    Button(action: model.signUp, label: {
                        if model.loading {
                            ProgressView()
                        }
                        else {
                            Text("Sign Up")
                                .font(.title)
                                .padding()
                                .foregroundColor(.white)
                                .frame(width: UIScreen.main.bounds.width-50, height: 60)
                            
                        }
                    })
                    .disabled(model.loading)
                    .background(Color("button"))
                    .cornerRadius(10)
                    .padding()
                    .shadow(radius: 4, x: 0, y: 3)
                    
                    
                }
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            
            
        }
    }
    
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
