//
//  Persistence.swift
//  travel
//
//  Created by Daniel Chung on 20/08/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<5 {
            let newTrip = Trip(context: viewContext)
            newTrip.name = "Sample Trip \(i + 1)"
            newTrip.category = ["Vacation", "Business", "Family Visit", "Adventure"][i % 4]
            newTrip.startDate = Date().addingTimeInterval(Double(i) * 86400)
            newTrip.endDate = Date().addingTimeInterval(Double(i + 7) * 86400)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "travel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}