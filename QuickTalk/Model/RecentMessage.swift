//
//  RecentMessage.swift
//  QuickTalk
//
//  Created by Елизавета on 19.08.2025.
//

import Foundation
import Firebase
import FirebaseFirestore

struct RecentMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    let documentId: String
    let text, email: String
    let fromId, toId: String
    let avatar: String
    let timestamp: Date
    
}
