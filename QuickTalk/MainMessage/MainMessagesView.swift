//
//  MainMessagesView.swift
//  QuickTalk
//
//  Created by Елизавета on 29.06.2025.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isCurrentlyLoggedOut = false
    
    init () {
        DispatchQueue.main.async {
            self.isCurrentlyLoggedOut =
            FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find uid"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user data \(error)"
                print("Error fetching current user: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "No user data found"
                return
            }
            
            let chatUser = ChatUser(data: data)
            self.chatUser = chatUser
        }
    }
    
    func handleSignOut() {
        isCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut
    }
}

struct MainMessagesView: View {
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewMessageScreen = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                
                customNavBar
                messagesView
            }
            // Расположение кнопки внизу
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private var customNavBar: some View {
        HStack {
            
            WebImage(url: URL(string: vm.chatUser?.avatar ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.email ?? "")")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(Color.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                }
            }
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Настройки"), message: Text("Что Вы хотите сделать?"), buttons: [
                .destructive(Text("Выйти из аккаунта"), action: {
                    print("выйти из аккаунта")
                    
                    vm.handleSignOut()
                }),
                .cancel(Text("Отменить"))
            ])
        }
        .fullScreenCover(isPresented: $vm.isCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 44)
                                .stroke(style: StrokeStyle(lineWidth: 1))
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Имя")
                                .font(.system(size: 16, weight: .bold))
                            Text("Сообщение отправлено пользователю")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                        
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ Написать")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
            })
        }
    }
}

#Preview {
    MainMessagesView()
}
