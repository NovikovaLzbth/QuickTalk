//
//  QuickTalkApp.swift
//  QuickTalk
//
//  Created by Елизавета on 28.06.2025.
//

import SwiftUI
import FirebaseCore

@main
struct QuickTalkApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                LoginView()
            }
        }
    }
}
