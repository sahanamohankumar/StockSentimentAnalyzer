
//  Final
//
//  Created by Sahana Mohankumar on 5/12/25.
//

import SwiftUI
import FirebaseCore

@main
struct FinalApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}


