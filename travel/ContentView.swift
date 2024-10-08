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
                if !currentTrips.isEmpty {
                    Section(header: Text("Current Trips")) {
                        ForEach(currentTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripRow(trip: trip)
                            }
                        }
                    }
                }
                
                if !upcomingTrips.isEmpty {
                    Section(header: Text("Upcoming Trips")) {
                        ForEach(upcomingTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripRow(trip: trip)
                            }
                        }
                    }
                }
                
                if !pastTrips.isEmpty {
                    Section(header: Text("Past Trips")) {
                        ForEach(pastTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripRow(trip: trip)
                            }
                        }
                    }
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
    
    private var currentTrips: [Trip] {
        let now = Date()
        return trips.filter { trip in
            guard let startDate = trip.startDate, let endDate = trip.endDate else { return false }
            return startDate <= now && endDate >= now
        }
    }
    
    private var upcomingTrips: [Trip] {
        let now = Date()
        return trips.filter { trip in
            guard let startDate = trip.startDate else { return false }
            return startDate > now
        }
    }
    
    private var pastTrips: [Trip] {
        let now = Date()
        return trips.filter { trip in
            guard let endDate = trip.endDate else { return false }
            return endDate < now
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
    @State private var category = "Select"
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    let categories = ["Select", "Vacation", "Business", "Family Visit", "Adventure"]
    
    private var isFormValid: Bool {
        !tripName.isEmpty && category != "Select" && startDate <= endDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Name")) {
                    TextField("Trip to Yosemite", text: $tripName)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .formStyle(GroupedFormStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add New Trip")
                        .font(.headline)
                }
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
                    .disabled(!isFormValid)
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