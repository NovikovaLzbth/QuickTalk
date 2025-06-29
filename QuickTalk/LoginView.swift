//
//  ContentView.swift
//  QuickTalk
//
//  Created by Елизавета on 28.06.2025.
//

import SwiftUI
import CoreData
import Firebase
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: NSObject {
    
    let auth: Auth
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    @State var loginStatusMessage = ""
    @State var shouldShowImagePicker = false
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
        }
    }
    
    //Создание аккаунта
    private func createNewAccount() {
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
        // Проверка и оптимизация изображения
        let optimizedImage = self.image?.resized(to: CGSize(width: 400, height: 400))
        guard let imageData = optimizedImage?.jpegData(compressionQuality: 0.7) else {
            self.loginStatusMessage = "Ошибка обработки изображения"
            return
        }
        
        // Проверка размера (Firestore ограничение 1MB)
        guard imageData.count <= 1_000_000 else {
            self.loginStatusMessage = "Изображение слишком большое (макс. 1MB)"
            return
        }
        
        // Сохранение в Firestore как Base64
        FirebaseManager.shared.firestore.collection("users").document(uid).setData([
            "email": self.email,
            "avatar": imageData.base64EncodedString(),
            "createdAt": Timestamp(),
            "uid": uid
        ]) { error in
            if let error = error {
                self.loginStatusMessage = "Ошибка сохранения: \(error.localizedDescription)"
            } else {
                self.loginStatusMessage = "Аватар успешно сохранён!"
            }
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
    LoginView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
