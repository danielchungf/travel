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
                            TripRow(trip: trip)
                        }
                    }
                }
                
                if !upcomingTrips.isEmpty {
                    Section(header: Text("Upcoming Trips")) {
                        ForEach(upcomingTrips) { trip in
                            TripRow(trip: trip)
                        }
                    }
                }
                
                if !pastTrips.isEmpty {
                    Section(header: Text("Past Trips")) {
                        ForEach(pastTrips) { trip in
                            TripRow(trip: trip)
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
        }
        .sheet(isPresented: $isAddingTrip) {
            AddTripView(isPresented: $isAddingTrip)
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
        NavigationLink(destination: TripDetailView(trip: trip)) {
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
                    Button("Add") {
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

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trip: Trip
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedCategory: String
    @State private var editedStartDate: Date
    @State private var editedEndDate: Date
    
    let categories = ["Vacation", "Business", "Family Visit", "Adventure"]
    
    init(trip: Trip) {
        self.trip = trip
        _editedName = State(initialValue: trip.name ?? "")
        _editedCategory = State(initialValue: trip.category ?? "")
        _editedStartDate = State(initialValue: trip.startDate ?? Date())
        _editedEndDate = State(initialValue: trip.endDate ?? Date())
    }
    
    var body: some View {
        Form {
            if isEditing {
                Section(header: Text("Trip Name")) {
                    TextField("Trip Name", text: $editedName)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $editedEndDate, displayedComponents: .date)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $editedCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section {
                    Button("Delete Trip", role: .destructive) {
                        deleteTrip()
                    }
                }
            } else {
                Section(header: Text("Trip Details")) {
                    Text("Name: \(trip.name ?? "")")
                    Text("Category: \(trip.category ?? "")")
                    Text("Start Date: \(trip.startDate ?? Date(), style: .date)")
                    Text("End Date: \(trip.endDate ?? Date(), style: .date)")
                }
            }
        }
        .navigationBarTitle(trip.name ?? "", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Trips") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
    }
    
    private func saveChanges() {
        trip.name = editedName
        trip.category = editedCategory
        trip.startDate = editedStartDate
        trip.endDate = editedEndDate
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func deleteTrip() {
        viewContext.delete(trip)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        dismiss()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}