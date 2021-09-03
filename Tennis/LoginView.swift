//
//  ContentView.swift
//  Tennis
//
//  Created by Stephen Byatt on 30/8/21.
//

import SwiftUI
import KeychainSwift
import Combine
import TennisAPI

class LoginModel: ViewModel {
    @Published var email = ""
    @Published var password = ""
    @Published var loading = false
    
    func login() {
        if email.isEmpty || password.isEmpty {
            return
        }
        loading = true
        defer { loading = false }
        
        AuthAPI.login(email: email, password: password).sink { completition in
            print(completition)
        } receiveValue: { res in
            if let token = res.token, let id = res.playerId {
                UserManager.current.login(token: token, id: id)
            }
        }
        .store(in: &cancellables)
        

    }
}

struct LoginView: View {
    @StateObject var model = LoginModel()
    @Environment(\.colorScheme) var currentColorScheme
    
    var body: some View {
        ZStack {
            Color("background")
                .ignoresSafeArea(.all)
            ScrollView {
                VStack {
                    Image("tennislogo")
                        .resizable()
                        .frame(width: 302, height: 261, alignment: .center)
                        .padding()
                    
                    Text("TENNIS")
                        .font(.largeTitle)
                        .scaleEffect(2)
                        .foregroundColor(Color("textfield"))
                        .flipColorScheme(currentColorScheme)
                        .padding()
                    
                    TextField("Email", text: $model.email)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(5)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.vertical)
                    
                    
                    SecureField("Password", text: $model.password)
                        .padding()
                        .background(Color("textfield"))
                        .cornerRadius(10)
                        .frame(width: UIScreen.main.bounds.width-50, height: 60)
                        .shadow(radius: 4, x: 0, y: 3)
                        .padding(.vertical)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(Color("button"))
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width-50)
                    
                    
                    Button(action: model.login, label: {
                        if model.loading {
                            ProgressView()
                        }
                        else {
                            Text("Log in")
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
                    
                    
                    NavigationLink(destination: SignUpView()) {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Color("textfield"))
                                .flipColorScheme(currentColorScheme)
                                .padding([.leading, .vertical])
                            Text("Sign Up")
                                .padding([.trailing, .vertical])
                                .foregroundColor(Color("button"))
                        }
                    }
                    
                    Spacer()
                    
                }
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("Login")
        .onAppear() {
            
            
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

