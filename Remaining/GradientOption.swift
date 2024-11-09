import SwiftUI

struct GradientOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    public let gradient: LinearGradient // Make this property public

    static func == (lhs: GradientOption, rhs: GradientOption) -> Bool {
        return lhs.id == rhs.id
    }
}

extension GradientOption {
    static let options = [
        GradientOption(name: "PinkPurple", gradient: LinearGradient(colors: [Color(hex2: "#0CDB47"), Color(hex2: "#0057FF")], startPoint: .leading, endPoint: .trailing)),
        GradientOption(name: "BlueGreen", gradient: LinearGradient(colors: [Color(hex2: "#EDD713"), Color(hex2: "#F41111")], startPoint: .leading, endPoint: .trailing)),
        GradientOption(name: "RedOrange", gradient: LinearGradient(colors: [Color(hex2: "#FF005C"), Color(hex2: "#0038FF")], startPoint: .leading, endPoint: .trailing)),
        GradientOption(name: "YellowPink", gradient: LinearGradient(colors: [Color(hex2: "#0CDB47"), Color(hex2: "#EDD713")], startPoint: .leading, endPoint: .trailing)),
        GradientOption(name: "GrayBlack", gradient: LinearGradient(colors: [Color(hex2: "#BC0EFA"), Color(hex2: "#FF005C")], startPoint: .leading, endPoint: .trailing))
    ]
}

extension GradientOption {
    static func gradient(for name: String) -> LinearGradient {
        return options.first(where: { $0.name == name })?.gradient ?? options.first!.gradient
    }
}

extension Color {
    init(hex2: String) {
        let scanner = Scanner(string: hex2)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
