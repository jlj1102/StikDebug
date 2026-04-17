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
            ToolItem(id: "scripts", title: NSLocalizedString("Scripts", comment: ""), detail: NSLocalizedString("Manage and run JS scripts", comment: ""), systemImage: "scroll", destination: AnyView(ScriptListView())),
            ToolItem(id: "console", title: NSLocalizedString("Console", comment: ""), detail: NSLocalizedString("Live device logs", comment: ""), systemImage: "terminal", destination: AnyView(ConsoleLogsView())),
            ToolItem(id: "deviceinfo", title: NSLocalizedString("Device Info", comment: ""), detail: NSLocalizedString("View detailed device metadata", comment: ""), systemImage: "iphone.and.arrow.forward", destination: AnyView(DeviceInfoView())),
            ToolItem(id: "profiles", title: NSLocalizedString("App Expiry", comment: ""), detail: NSLocalizedString("Check app expiration dates", comment: ""), systemImage: "calendar.badge.clock", destination: AnyView(ProfileView())),
            ToolItem(id: "processes", title: NSLocalizedString("Processes", comment: ""), detail: NSLocalizedString("Inspect running apps", comment: ""), systemImage: "rectangle.stack.person.crop", destination: AnyView(ProcessInspectorView())),
            ToolItem(id: "location", title: NSLocalizedString("Location Simulation", comment: ""), detail: NSLocalizedString("Simulate GPS location", comment: ""), systemImage: "location", destination: AnyView(LocationSimulationView()))
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
            .navigationTitle(NSLocalizedString("Tools", comment: ""))
        }
    }
}
