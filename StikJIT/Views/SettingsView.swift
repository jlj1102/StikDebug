//  SettingsView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.

import SwiftUI
import UIKit

struct SettingsView: View {

    @AppStorage("selectedAppIcon") private var selectedAppIcon: String = "AppIcon"
    @AppStorage("enableAdvancedOptions") private var enableAdvancedOptions = false
    @AppStorage("enableAdvancedBetaOptions") private var enableAdvancedBetaOptions = false
    @AppStorage("enableTesting") private var enableTesting = false
    @AppStorage(UserDefaults.Keys.txmOverride) private var overrideTXMDetection = false
    @AppStorage("keepAliveAudio") private var keepAliveAudio = true
    @AppStorage("keepAliveLocation") private var keepAliveLocation = true
    @AppStorage("customTargetIP") private var customTargetIP = ""
    @AppStorage(TabConfiguration.storageKey) private var enabledTabIdentifiers = TabConfiguration.defaultRawValue
    @AppStorage("primaryTabSelection") private var tabSelection = TabConfiguration.defaultIDs.first ?? "home"
    
    @State private var isShowingPairingFilePicker = false
    @State private var showPairingFileMessage = false
    @State private var isImportingFile = false
    @State private var importProgress: Float = 0.0
    @State private var pairingStatusMessage: String? = nil
    @State private var showDDIConfirmation = false
    @State private var isRedownloadingDDI = false
    @State private var ddiDownloadProgress: Double = 0.0
    @State private var ddiStatusMessage: String = ""
    @State private var ddiResultMessage: (text: String, isError: Bool)?


    private var appVersion: String {
        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return marketingVersion
    }
    
    struct TabOption: Identifiable {
        let id: String
        let title: String
        let detail: String
        let icon: String
        let isBeta: Bool
    }
    
    private var tabOptions: [TabOption] {
        var options: [TabOption] = [
            TabOption(id: "home", title: String("Home".localized), detail: String("Dashboard overview".localized), icon: "house", isBeta: false),
            TabOption(id: "scripts", title: String("Scripts".localized), detail: String("Manage automation scripts".localized), icon: "scroll", isBeta: false),
            TabOption(id: "tools", title: String("Tools".localized), detail: String("Access additional tools".localized), icon: "wrench.and.screwdriver", isBeta: false)
        ]
        options.append(TabOption(id: "deviceinfo", title: String("Device Info".localized), detail: String("View detailed device metadata".localized), icon: "iphone.and.arrow.forward", isBeta: false))
        options.append(TabOption(id: "profiles", title: String("App Expiry".localized), detail: String("Check app expiration date, install/remove profiles".localized), icon: "calendar.badge.clock", isBeta: false))
        options.append(TabOption(id: "processes", title: String("Processes".localized), detail: String("Inspect running apps".localized), icon: "rectangle.stack.person.crop", isBeta: false))
        options.append(TabOption(id: "location", title: String("Location Sim".localized), detail: String("Sideload only".localized), icon: "location", isBeta: false))
        return options
    }

    var body: some View {
        NavigationStack {
            Form {
                // 1) App Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image("StikDebug")
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Text("StikDebug").font(.title2.weight(.semibold))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                // 2) GitHub
                Section {
                    Link(destination: URL(string: "https://github.com/StephenDev0/StikDebug/stargazers")!) {
                        Label(String(format: "Star on GitHub".localized), systemImage: "star")
                    }
                }

                // 3) Pairing File
                Section(String(format: "Pairing File".localized)) {
                    Button { isShowingPairingFilePicker = true } label: {
                        Label(String(format: "Import Pairing File".localized), systemImage: "doc.badge.plus")
                    }
                    if showPairingFileMessage && !isImportingFile {
                        Label(String(format: "Imported successfully".localized), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                // 5) Background Keep-Alive
                Section {
                    Toggle(isOn: $keepAliveAudio) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Silent Audio".localized))
                            Text(String(format: "Plays inaudible audio so iOS keeps the app running.".localized))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: keepAliveAudio) { _, enabled in
                        if enabled { BackgroundAudioManager.shared.start() }
                        else { BackgroundAudioManager.shared.stop() }
                    }

                    Toggle(isOn: $keepAliveLocation) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Background Location".localized))
                            Text(String(format: "Uses low-accuracy location to stay alive when an activity needs it.".localized))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: keepAliveLocation) { _, enabled in
                        if !enabled { BackgroundLocationManager.shared.stop() }
                    }

                } header: {
                    Text(String(format: "Background Keep-Alive".localized))
                }

                // 6) Behavior
                Section(String(format: "Behavior".localized)) {
                    Toggle(isOn: $overrideTXMDetection) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Always Run Scripts".localized))
                            Text(String(format: "Treats device as TXM-capable to bypass hardware checks.".localized))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                // 7) Advanced
                Section(String(format: "Advanced".localized)) {
                    HStack {
                        Text(String(format: "Target Device IP".localized))
                        Spacer()
                        TextField("10.7.0.1", text: $customTargetIP)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .submitLabel(.done)
                    }
                    Button { openAppFolder() } label: {
                        Label(String(format: "App Folder".localized), systemImage: "folder")
                    }.foregroundStyle(.primary)
                    Button { showDDIConfirmation = true } label: {
                        Label(String(format: "Redownload DDI".localized), systemImage: "arrow.down.circle")
                    }.foregroundStyle(.primary).disabled(isRedownloadingDDI)
                    if isRedownloadingDDI {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: ddiDownloadProgress, total: 1.0)
                            Text(ddiStatusMessage).font(.caption).foregroundStyle(.secondary)
                        }
                    } else if let result = ddiResultMessage {
                        Text(result.text).font(.caption).foregroundStyle(result.isError ? .red : .green)
                    }
                }

                // 7) Help
                Section(String(format: "Help".localized)) {
                    Link(destination: URL(string: "https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")!) {
                        Label(String(format: "Pairing File Guide".localized), systemImage: "questionmark.circle")
                    }
                    Link(destination: URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!) {
                        Label(String(format: "Download LocalDevVPN".localized), systemImage: "arrow.down.circle")
                    }
                    Link(destination: URL(string: "https://discord.gg/qahjXNTDwS")!) {
                        Label(String(format: "Discord Support".localized), systemImage: "bubble.left.and.bubble.right")
                    }
                }

                // 8) Version footer
                Section {
                    Text(versionFooter)
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(String(format: "Settings".localized))
        }
            .fileImporter(
            isPresented: $isShowingPairingFilePicker,
            allowedContentTypes: PairingFileStore.supportedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }

                let fileManager = FileManager.default
                do {
                    try PairingFileStore.importFromPicker(url, fileManager: fileManager)
                    DispatchQueue.main.async {
                        isImportingFile = true
                        importProgress = 0.0
                        pairingStatusMessage = nil
                        showPairingFileMessage = false
                    }

                    let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                        DispatchQueue.main.async {
                            if importProgress < 1.0 {
                                importProgress += 0.05
                            } else {
                                timer.invalidate()
                                isImportingFile = false
                            }
                        }
                    }

                    RunLoop.current.add(progressTimer, forMode: .common)
                    DispatchQueue.main.async {
                        startTunnelInBackground()
                    }
                } catch {
                    break
                }
            case .failure:
                break
            }
        }
        .confirmationDialog(String(format: "Redownload DDI Files?".localized), isPresented: $showDDIConfirmation, titleVisibility: .visible) {
            Button(String(format: "Redownload".localized), role: .destructive) {
                redownloadDDIPressed()
            }
            Button(String(format: "Cancel".localized), role: .cancel) { }
        } message: {
            Text(String(format: "Existing DDI files will be removed before downloading fresh copies.".localized))
        }
        .overlay { if isImportingFile { importBusyOverlay } }
    }

    @ViewBuilder
    private var importBusyOverlay: some View {
        Color.black.opacity(0.35).ignoresSafeArea()
        VStack(spacing: 12) {
            ProgressView(String(format: "Processing pairing file…".localized))
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(importProgress), height: 8)
                            .animation(.linear(duration: 0.3), value: importProgress)
                    }
                }
                .frame(height: 8)
                Text("\(Int(importProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    private var versionFooter: String {
        let processInfo = ProcessInfo.processInfo
        let txmLabel: String
        if processInfo.isTXMOverridden {
            txmLabel = String(format: "TXM (Override)".localized)
        } else {
            txmLabel = processInfo.hasTXM ? String(format: "TXM".localized) : String(format: "Non TXM".localized)
        }
        return String(format: "Version %@ • iOS %@ • %@", appVersion, UIDevice.current.systemVersion, txmLabel)
    }
    
    // MARK: - Business Logic

    private func openAppFolder() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let path = documentsURL.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        if let url = URL(string: path) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func redownloadDDIPressed() {
        guard !isRedownloadingDDI else { return }
        Task {
            await MainActor.run {
                isRedownloadingDDI = true
                ddiDownloadProgress = 0
                ddiStatusMessage = String(format: "Preparing download…".localized)
                ddiResultMessage = nil
            }
            do {
                try await redownloadDDI { progress, status in
                    Task { @MainActor in
                        self.ddiDownloadProgress = progress
                        self.ddiStatusMessage = status
                    }
                }
                await MainActor.run {
                    isRedownloadingDDI = false
                    ddiResultMessage = ("DDI files refreshed successfully.", false)
                }
            } catch {
                await MainActor.run {
                    isRedownloadingDDI = false
                    ddiResultMessage = ("Failed to redownload DDI files: \(error.localizedDescription)", true)
                }
            }
        }
        scheduleDDIStatusDismiss()
    }
    
    private func scheduleDDIStatusDismiss() {
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                if !isRedownloadingDDI {
                    ddiResultMessage = nil
                }
            }
        }
    }
}

// MARK: - Tab Customization

struct TabCustomizationView: View {
    let tabOptions: [SettingsView.TabOption]
    @Binding var enabledTabIdentifiers: String
    @Binding var tabSelection: String

    private var selectedIDs: [String] {
        TabConfiguration.sanitize(raw: enabledTabIdentifiers)
    }

    private var pinnedOptions: [SettingsView.TabOption] {
        selectedIDs.compactMap { id in tabOptions.first(where: { $0.id == id }) }
    }

    private var availableOptions: [SettingsView.TabOption] {
        tabOptions.filter { !selectedIDs.contains($0.id) }
    }

    var body: some View {
        List {
            Section {
                ForEach(pinnedOptions) { option in
                    HStack {
                        Label(option.title, systemImage: option.icon)
                    }
                }
                .onMove { indices, newOffset in
                    var ids = selectedIDs
                    ids.move(fromOffsets: indices, toOffset: newOffset)
                    enabledTabIdentifiers = TabConfiguration.serialize(ids)
                }
            } header: {
                Text(NSLocalizedString("Pinned", comment: ""))
            } footer: {
                Text(NSLocalizedString("Settings is fixed as the 4th tab.", comment: ""))
            }

            if !availableOptions.isEmpty {
                Section(NSLocalizedString("Available", comment: "")) {
                    ForEach(availableOptions) { option in
                        Button {
                            var ids = selectedIDs
                            guard ids.count < TabConfiguration.maxSelectableTabs else { return }
                            ids.append(option.id)
                            enabledTabIdentifiers = TabConfiguration.serialize(ids)
                        } label: {
                            HStack {
                                Label(option.title, systemImage: option.icon)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Tab Bar", comment: ""))
        .toolbar {
            EditButton()
        }
    }
}

struct ConsoleLogsView_Preview: PreviewProvider {
    static var previews: some View {
        ConsoleLogsView()
    }
}
