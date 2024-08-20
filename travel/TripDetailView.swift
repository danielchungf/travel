import SwiftUI
import CoreData

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var trip: Trip
    @State private var isEditing = false
    
    var body: some View {
        Form {
            Section(header: Text("Trip Details")) {
                Text("Name: \(trip.name ?? "")")
                Text("Category: \(trip.category ?? "")")
                Text("Start Date: \(formattedDate(trip.startDate))")
                Text("End Date: \(formattedDate(trip.endDate))")
            }
        }
        .navigationBarTitle(trip.name ?? "", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Trips") {
                self.presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("Edit") {
                isEditing = true
            }
        )
        .sheet(isPresented: $isEditing) {
            EditTripView(trip: trip, isPresented: $isEditing)
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditTripView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var trip: Trip
    @Binding var isPresented: Bool
    
    @State private var editedName: String
    @State private var editedCategory: String
    @State private var editedStartDate: Date
    @State private var editedEndDate: Date
    
    let categories = ["Vacation", "Business", "Family Visit", "Adventure"]
    
    init(trip: Trip, isPresented: Binding<Bool>) {
        self.trip = trip
        self._isPresented = isPresented
        _editedName = State(initialValue: trip.name ?? "")
        _editedCategory = State(initialValue: trip.category ?? "")
        _editedStartDate = State(initialValue: trip.startDate ?? Date())
        _editedEndDate = State(initialValue: trip.endDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
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
            }
            .navigationBarTitle("Edit Trip", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveChanges()
                    isPresented = false
                }
            )
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
            print("Error saving context: \(error)")
        }
    }
    
    private func deleteTrip() {
        viewContext.delete(trip)
        do {
            try viewContext.save()
            isPresented = false
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting trip: \(error)")
        }
    }
}