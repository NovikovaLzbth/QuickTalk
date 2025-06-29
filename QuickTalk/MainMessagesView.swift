//
//  MainMessagesView.swift
//  QuickTalk
//
//  Created by Елизавета on 29.06.2025.
//

import SwiftUI

struct MainMessagesView: View {
    @State var shouldShowLogOutOptions = false
    
    var body: some View {
        NavigationStack {
            VStack {
                customNavBarStyle
                messagesView
            }
            // Расположение кнопки внизу
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private var customNavBarStyle: some View {
        HStack {
            Image(systemName: "person.fill")
                .font(.system(size: 34,weight: .heavy))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
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
                }),
                .cancel(Text("Отменить"))
            ])
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
    }
}

#Preview {
    MainMessagesView()
}
