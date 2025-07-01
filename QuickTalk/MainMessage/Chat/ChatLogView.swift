//
//  ChatLogView.swift
//  QuickTalk
//
//  Created by Елизавета on 01.07.2025.
//

import SwiftUI
import Firebase

struct FirebaseConatants {
    static let fromId = "fromID"
    static let toId = "toId"
    static let text = "text"
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConatants.fromId] as? String ?? ""
        self.toId = data[FirebaseConatants.toId] as? String ?? ""
        self.text = data[FirebaseConatants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    @Published var count = 0
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Error listening for messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                DispatchQueue.main.async {
                    // Прокрутка к новому сообщению
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        print(chatText)
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document =
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConatants.fromId: fromId, FirebaseConatants.toId: toId, FirebaseConatants.text: self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) {error in
            if let error = error {
                self.errorMessage = "\(error)"
            }
            print("Успешно сохранено")
            self.chatText = ""
            // Прокрутка к новому сообщению
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) {error in
            if let error = error {
                self.errorMessage = "\(error)"
            }
            print("Реципиент")
        }
    }
}

struct ChatLogView: View {
    @FocusState private var isTextFieldFocused: Bool
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        VStack {
            messagesView
            chatBottomBar
                .background(Color.white)
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { _ in
                    isTextFieldFocused = false
                }
        )
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        ScrollView {
            // ScrollViewReader для прокрутки к новым сообщениям
            ScrollViewReader { scrollViewProxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        MessageView(message: message)
                    }
                    HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
    }
    
    private var chatBottomBar: some View {
        HStack {
            Image(systemName: "photo.on.rectangle.angled")
                .foregroundColor(Color(.darkGray))
                .font(.system(size: 20))
            
            TextField("Сообщение", text: $vm.chatText)
                .font(.system(size: 17))
                .focused($isTextFieldFocused)
            
            Button {
                vm.handleSend()
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 3)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatLogView(chatUser: .init(data: [
                "uid": "real user id",
                "email": "email@gmail.com"
            ]))
        }
    }
}
