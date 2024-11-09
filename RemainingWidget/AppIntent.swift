import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Choose the view style for your widget.")

    @Parameter(title: "View Style", default: .singleProgressBar)
    var viewStyle: ViewStyle
}

enum ViewStyle: String, AppEnum {
    case singleProgressBar
    case doubleProgressBar

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "View Style"
    }

    static var caseDisplayRepresentations: [ViewStyle: DisplayRepresentation] {
        [
            .singleProgressBar: "Single Progress Bar",
            .doubleProgressBar: "Double Progress Bar"
        ]
    }
}
