import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: true)],
        animation: .default)
    private var trips: FetchedResults<Trip>
    
    @State private var isAddingTrip = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(trips) { trip in
                    TripRow(trip: trip)
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingTrip = true }) {
                        Label("Add Trip", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTrip) {
                AddTripView(isPresented: $isAddingTrip)
            }
        }
    }
}

struct TripRow: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(trip.name ?? "")
                .font(.headline)
            Text(trip.category ?? "")
                .font(.subheadline)
            Text("\(trip.startDate ?? Date(), style: .date) - \(trip.endDate ?? Date(), style: .date)")
                .font(.caption)
        }
    }
}

struct AddTripView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var tripName = ""
    @State private var category = "Vacation"
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    let categories = ["Vacation", "Business", "Family Visit", "Adventure"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Trip Name", text: $tripName)
                
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTrip()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Add New Trip")
                        .font(.headline)
                }
            }
        }
    }
    
    private func addTrip() {
        let newTrip = Trip(context: viewContext)
        newTrip.name = tripName
        newTrip.category = category
        newTrip.startDate = startDate
        newTrip.endDate = endDate
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}