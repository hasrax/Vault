//
//  vaultLiveActivity.swift
//  vault
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-04.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct vaultAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct vaultLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: vaultAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
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

extension vaultAttributes {
    fileprivate static var preview: vaultAttributes {
        vaultAttributes(name: "World")
    }
}

extension vaultAttributes.ContentState {
    fileprivate static var smiley: vaultAttributes.ContentState {
        vaultAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: vaultAttributes.ContentState {
         vaultAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: vaultAttributes.preview) {
   vaultLiveActivity()
} contentStates: {
    vaultAttributes.ContentState.smiley
    vaultAttributes.ContentState.starEyes
}
