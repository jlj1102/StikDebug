//
//  ToolsView.swift
//  StikJIT
//
//  Created by Stephen on 2/23/26.
//

import SwiftUI

struct ToolsView: View {
    private struct ToolItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
        let destination: AnyView
    }

    private var tools: [ToolItem] {
        [
            ToolItem(id: "scripts", title: String(format: "Scripts".localized), detail: String(format: "Manage and run JS scripts".localized), systemImage: "scroll", destination: AnyView(ScriptListView())),
            ToolItem(id: "console", title: String(format: "Console".localized), detail: String(format: "Live device logs".localized), systemImage: "terminal", destination: AnyView(ConsoleLogsView())),
            ToolItem(id: "deviceinfo", title: String(format: "Device Info".localized), detail: String(format: "View detailed device metadata".localized), systemImage: "iphone.and.arrow.forward", destination: AnyView(DeviceInfoView())),
            ToolItem(id: "profiles", title: String(format: "App Expiry".localized), detail: String(format: "Check app expiration dates".localized), systemImage: "calendar.badge.clock", destination: AnyView(ProfileView())),
            ToolItem(id: "processes", title: String(format: "Processes".localized), detail: String(format: "Inspect running apps".localized), systemImage: "rectangle.stack.person.crop", destination: AnyView(ProcessInspectorView())),
            ToolItem(id: "location", title: String(format: "Location Simulation".localized), detail: String(format: "Simulate GPS location".localized), systemImage: "location", destination: AnyView(LocationSimulationView()))
        ]
    }

    var body: some View {
        NavigationStack {
            List(tools) { tool in
                NavigationLink {
                    tool.destination
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.title)
                            Text(tool.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: tool.systemImage)
                    }
                }
            }
            .navigationTitle(String(format: "Tools".localized))
        }
    }
}
