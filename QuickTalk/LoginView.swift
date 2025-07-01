//
//  ContentView.swift
//  QuickTalk
//
//  Created by Елизавета on 28.06.2025.
//

import SwiftUI
import Firebase

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var loginStatusMessage = ""
    @State private var shouldShowImagePicker = false
    @State var image: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label:
                            Text("Picker here")) {
                        Text("Войти")
                            .tag(true)
                        Text("Создать Аккаунт")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 128)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 3)
                                        )
                                    
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                        .overlay(RoundedRectangle(cornerRadius: 64)
                                            .stroke(Color.black, lineWidth: 3))
                                }
                            }
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Пароль", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Войти" : "Создать Аккаунт")
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                             .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Войти" : "Создать Аккаунт")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea(.all))
        }
        // Доступ к галерее
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    private  func handleAction() {
        if isLoginMode {
            print("Should log into Firebase with existing credentials")
            loginUser()
        } else {
            createNewAccount()
            //            print("Register a new account inside of Firebase")
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, error in
            if let err = error {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            print("Success logged user: \(result?.user.uid ?? "No UID")")
            self.loginStatusMessage = "Success logged user: \(result?.user.uid ?? "No UID")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    //Создание аккаунта
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "Выберите аватар профиля"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, error in
            if let err = error {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            print("Success creating user: \(result?.user.uid ?? "No UID")")
            self.loginStatusMessage = "Success creating user: \(result?.user.uid ?? "No UID")"
            
            guard let uid = result?.user.uid else { return }
            self.loginStatusMessage = "Аккаунт создан!"
            
            // Сохранение аватарки
            self.saveAvatar(uid: uid)
        }
    }
    
    // Простой метод сохранения аватарки
    private func saveAvatar(uid: String) {
        guard let image = self.image?.resized(to: CGSize(width: 400, height: 400)),
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            return
        }
        
        guard imageData.count <= 1_000_000 else {
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        FirebaseManager.shared.firestore.collection("users").document(uid).setData([
            "email": self.email,
            "avatar": base64String, // Сохраняем как Base64 строку
            "uid": uid ]) { error in
                if let error = error {
                    self.loginStatusMessage = "Ошибка сохранения: \(error.localizedDescription)"
                }
                
                self.didCompleteLoginProcess()
            }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    LoginView(didCompleteLoginProcess: {
        
    }).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
