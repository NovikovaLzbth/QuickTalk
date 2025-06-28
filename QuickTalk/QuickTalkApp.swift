//
//  QuickTalkApp.swift
//  QuickTalk
//
//  Created by Елизавета on 28.06.2025.
//

import SwiftUI

@main
struct QuickTalkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
