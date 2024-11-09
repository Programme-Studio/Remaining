//
//  RemainingWidgetLiveActivity.swift
//  RemainingWidget
//
//  Created by Peter Bruce on 02/06/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RemainingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
    }
    var name: String
}

struct RemainingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RemainingWidgetAttributes.self) { context in
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RemainingWidgetAttributes {
    fileprivate static var preview: RemainingWidgetAttributes {
        RemainingWidgetAttributes(name: "World")
    }
}

extension RemainingWidgetAttributes.ContentState {
    fileprivate static var smiley: RemainingWidgetAttributes.ContentState {
        RemainingWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RemainingWidgetAttributes.ContentState {
         RemainingWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RemainingWidgetAttributes.preview) {
   RemainingWidgetLiveActivity()
} contentStates: {
    RemainingWidgetAttributes.ContentState.smiley
    RemainingWidgetAttributes.ContentState.starEyes
}
