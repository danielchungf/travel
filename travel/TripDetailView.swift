import SwiftUI
import CoreData

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var trip: Trip
    @State private var isEditing = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            TabView(selection: $selectedTab) {
                PackView(trip: trip)
                    .tag(0)
                
                PlanView(trip: trip)
                    .tag(1)
                
                VisitView(trip: trip)
                    .tag(2)
                
                EatView(trip: trip)
                    .tag(3)
                
                BudgetView(trip: trip)
                    .tag(4)
            }
            
            // Divider above the tab bar
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.bottom, 2) // Add 2 points of padding below the divider
            
            // Custom tab bar
            HStack {
                ForEach(0..<5) { index in
                    Spacer()
                    VStack {
                        Image(systemName: self.iconName(for: index))
                            .foregroundColor(self.selectedTab == index ? .blue : .gray)
                        Text(self.tabName(for: index))
                            .font(.caption)
                            .foregroundColor(self.selectedTab == index ? .blue : .gray)
                    }
                    .onTapGesture {
                        self.selectedTab = index
                    }
                    Spacer()
                }
            }
            .frame(height: 49)
            .padding(.bottom, 30) // Increased padding to 32 points
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarTitle(trip.name ?? "", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("Trips")
                }
            },
            trailing: Button("Edit") {
                isEditing = true
            }
        )
        .sheet(isPresented: $isEditing) {
            EditTripView(trip: trip, isPresented: $isEditing)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func iconName(for index: Int) -> String {
        switch index {
        case 0: return "suitcase.fill"
        case 1: return "calendar"
        case 2: return "mappin.and.ellipse"
        case 3: return "fork.knife"
        case 4: return "dollarsign.circle.fill"
        default: return ""
        }
    }
    
    private func tabName(for index: Int) -> String {
        switch index {
        case 0: return "Pack"
        case 1: return "Plan"
        case 2: return "Visit"
        case 3: return "Eat"
        case 4: return "Budget"
        default: return ""
        }
    }
}

struct CustomTabItem: View {
    let imageName: String
    let title: String
    
    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(title)
        }
    }
}

// Placeholder views for each tab
struct PackView: View {
    let trip: Trip
    var body: some View {
        Text("Pack view for \(trip.name ?? ""). Add all the items you need to pack for your trip.")
    }
}

struct PlanView: View {
    let trip: Trip
    var body: some View {
        Text("Plan view for \(trip.name ?? ""). Add your accomodations, flights, activities, transportation, and more.")
    }
}

struct VisitView: View {
    let trip: Trip
    var body: some View {
        Text("Visit view for \(trip.name ?? ""). Add all the places you want to visit.")
    }
}

struct EatView: View {
    let trip: Trip
    var body: some View {
        Text("Eat view for \(trip.name ?? ""). Add all the restaurant recommendations and dishes you want to try.")
    }
}

struct BudgetView: View {
    let trip: Trip
    var body: some View {
        Text("Budget view for \(trip.name ?? ""). Track every dollar spent on this trip.")
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
    @State private var showingDeleteAlert = false
    
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
                        showingDeleteAlert = true
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
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Trip"),
                    message: Text("Are you sure you want to delete '\(trip.name ?? "")'?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteTrip()
                    },
                    secondaryButton: .cancel()
                )
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