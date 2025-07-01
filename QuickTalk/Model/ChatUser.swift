//
//  ChatUser.swift
//  QuickTalk
//
//  Created by Елизавета on 01.07.2025.
//

import Foundation
import Firebase

struct ChatUser: Identifiable {
    
    var id: String { uid }
    
    let uid: String
    let email: String
    let avatar: String
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        let avatarBase64 = data["avatar"] as? String ?? ""
        self.avatar = avatarBase64.isEmpty ? "default_avatar_url" : "data:image/jpeg;base64,\(avatarBase64)"
    }
}
