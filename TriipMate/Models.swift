import Foundation

struct Ride: Identifiable, Hashable {
    let id = UUID()
    let driver: String
    let initials: String
    let from: String
    let to: String
    let date: String
    let time: String
    let endTime: String
    let tripTime: String
    let seats: Int
    let totalSeats: Int
    let price: Int
    let vehicle: String
    let carMake: String
    let carModel: String
    let carYear: String
    let powerType: String
    let bodyType: String
    let rating: Double
    let verified: Bool
    let notes: String
}

struct MessageThread: Identifiable {
    let id = UUID()
    let name: String
    let route: String
    let message: String
    let time: String
    let unread: Bool
}

enum SampleData {
    static let rides: [Ride] = [
        Ride(driver: "Maya Chen", initials: "MC", from: "New York, NY", to: "Chicago, IL", date: "Jun 18", time: "7:30 AM", endTime: "8:45 PM", tripTime: "14h 15m", seats: 2, totalSeats: 5, price: 148, vehicle: "Toyota Highlander", carMake: "Toyota", carModel: "Highlander", carYear: "2022", powerType: "Hybrid", bodyType: "SUV", rating: 4.9, verified: true, notes: "Room for two carry-ons. Planning one food stop and one gas stop."),
        Ride(driver: "Darius Hill", initials: "DH", from: "Boston, MA", to: "Detroit, MI", date: "Jun 19", time: "6:00 AM", endTime: "7:30 PM", tripTime: "13h 30m", seats: 3, totalSeats: 7, price: 132, vehicle: "Honda Odyssey", carMake: "Honda", carModel: "Odyssey", carYear: "2021", powerType: "Fuel", bodyType: "Van", rating: 4.8, verified: true, notes: "Easy route through upstate New York. Flexible pickup near the highway."),
        Ride(driver: "Elena Garcia", initials: "EG", from: "Philadelphia, PA", to: "Pittsburgh, PA", date: "Jun 20", time: "9:15 AM", endTime: "2:30 PM", tripTime: "5h 15m", seats: 1, totalSeats: 5, price: 64, vehicle: "Subaru Outback", carMake: "Subaru", carModel: "Outback", carYear: "2020", powerType: "Fuel", bodyType: "Sedan", rating: 4.7, verified: false, notes: "Quiet ride, no smoking, small backpack preferred.")
    ]

    static let messages: [MessageThread] = [
        MessageThread(name: "Maya Chen", route: "NYC to Chicago", message: "Pickup near Penn Station works for me.", time: "2m", unread: true),
        MessageThread(name: "Darius Hill", route: "Boston to Detroit", message: "I can save a seat until tonight.", time: "1h", unread: true),
        MessageThread(name: "Elena Garcia", route: "Philly to Pittsburgh", message: "Thanks, see you Saturday morning.", time: "Yesterday", unread: false)
    ]
}
