import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var amount: Double
    var category: String
    var note: String
    var date: Date
}

enum ExpenseCategory {
    static func icon(for category: String) -> String {
        switch category {
        case "Lebensmittel": "basket"
        case "Transport": "tram"
        case "Wohnen": "house"
        case "Freizeit": "sparkles"
        case "Gesundheit": "cross.case"
        default: "eurosign.circle"
        }
    }
}
