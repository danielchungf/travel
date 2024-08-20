//
//  travelApp.swift
//  travel
//
//  Created by Daniel Chung on 20/08/24.
//

import SwiftUI

@main
struct travelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
