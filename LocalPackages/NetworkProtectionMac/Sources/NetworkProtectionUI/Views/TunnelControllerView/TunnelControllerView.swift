//
//  TunnelControllerView.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import SwiftUIExtensions
import Combine
import NetworkProtection
import Lottie

fileprivate extension Font {
    enum NetworkProtection {
        static var connectionStatusDetail: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var dataVolume: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var currentSite: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var location: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var content: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var description: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var label: Font {
            .system(size: 13, weight: .regular, design: .default)
        }

        static var sectionHeader: Font {
            .system(size: 12, weight: .semibold, design: .default)
        }

        static var timer: Font {
            .system(size: 13, weight: .regular, design: .default)
            .monospacedDigit()
        }

        static var title: Font {
            .system(size: 15, weight: .semibold, design: .default)
        }
    }
}

private enum Opacity {
    static func connectionStatusDetail(colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? Double(0.6) : Double(0.5)
    }

    static func dataVolume(colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? Double(0.6) : Double(0.5)
    }

    static let content = Double(0.58)
    static let label = Double(0.9)
    static let link = Double(1)

    static func sectionHeader(colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? Double(0.84) : Double(0.85)
    }

    static func timer(colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? Double(0.6) : Double(0.5)
    }

    static func title(colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? Double(0.84) : Double(0.85)
    }
}

fileprivate extension View {
    func applyConnectionStatusDetailAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.connectionStatusDetail(colorScheme: colorScheme))
            .font(.NetworkProtection.connectionStatusDetail)
            .foregroundColor(Color(.defaultText))
    }

    func applyDataVolumeAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.dataVolume(colorScheme: colorScheme))
            .font(.NetworkProtection.dataVolume)
            .foregroundColor(Color(.defaultText))
    }

    func applyCurrentSiteAttributes() -> some View {
        font(.NetworkProtection.currentSite)
    }

    func applyLocationAttributes() -> some View {
        font(.NetworkProtection.location)
    }

    func applyContentAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.content)
            .font(.NetworkProtection.content)
            .foregroundColor(Color(.defaultText))
    }

    func applyDescriptionAttributes() -> some View {
        font(.NetworkProtection.description)
            .foregroundColor(Color(.secondaryText))
    }

    func applyLabelAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.label)
            .font(.NetworkProtection.label)
            .foregroundColor(Color(.defaultText))
    }

    func applySectionHeaderAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.sectionHeader(colorScheme: colorScheme))
            .font(.NetworkProtection.sectionHeader)
            .foregroundColor(Color(.defaultText))
    }

    func applyTimerAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.timer(colorScheme: colorScheme))
            .font(.NetworkProtection.timer)
            .foregroundColor(Color(.defaultText))
    }

    func applyTitleAttributes(colorScheme: ColorScheme) -> some View {
        opacity(Opacity.title(colorScheme: colorScheme))
            .font(.NetworkProtection.title)
            .foregroundColor(Color(.defaultText))
    }
}

public struct TunnelControllerView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dismiss) private var dismiss

    // MARK: - Model

    /// The view model that this instance will use.
    ///
    @ObservedObject var model: TunnelControllerViewModel

    // MARK: - Initializers

    public init(model: TunnelControllerViewModel) {
        self.model = model
    }

    // MARK: - View Contents

    public var body: some View {
        Group {
            headerView()
                .disabled(on: !isEnabled)

            featureToggleRow()

            Divider()
                .padding(EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))

            SiteTroubleshootingView()

            locationView()

            if model.showServerDetails {
                connectionStatusView()
                    .disabled(on: !isEnabled)
            }
        }
    }

    // MARK: - Composite Views

    /// Main image, feature ON/OFF and feature description
    ///
    private func headerView() -> some View {
        VStack(spacing: 0) {
            headerAnimationView()
                .frame(width: 100, height: 75)

            Text(model.featureStatusDescription)
                .applyTitleAttributes(colorScheme: colorScheme)
                .padding([.top], 8)
                .multilineText()

            Text(model.isToggleOn.wrappedValue ? UserText.networkProtectionStatusHeaderMessageOn : UserText.networkProtectionStatusHeaderMessageOff)
                .multilineText()
                .multilineTextAlignment(.center)
                .applyDescriptionAttributes()
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
        }
    }

    @ViewBuilder
    private func headerAnimationView() -> some View {
        if colorScheme == .light {
            headerAnimationView("vpn-light-mode")
        } else {
            headerAnimationView("vpn-dark-mode")
        }
    }

    @ViewBuilder
    private func headerAnimationView(_ animationName: String) -> some View {
        LottieView(animation: .named(animationName))
            .playing(withIntro: .init(
                    skipIntro: model.isVPNEnabled && !model.isToggleDisabled,
                    introStartFrame: 0,
                    introEndFrame: 100,
                    loopStartFrame: 130,
                    loopEndFrame: 370
                ), isAnimating: $model.isVPNEnabled)
    }

    @ViewBuilder
    private func statusBadge(isConnected: Bool) -> some View {
        Circle()
            .fill(isConnected ? .green : .yellow)
            .frame(width: 8, height: 8)
    }

    /// Connected/Selected location
    ///
    private func locationView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.isVPNEnabled ? UserText.vpnLocationConnected : UserText.vpnLocationSelected)
                .applySectionHeaderAttributes(colorScheme: colorScheme)
                .padding(EdgeInsets(top: 6, leading: 9, bottom: 6, trailing: 9))

            MenuItemCustomButton {
                model.showLocationSettings()
                dismiss()
            } label: { isHovered in
                HStack(alignment: .center, spacing: 10) {
                    if let emoji = model.emoji {
                        Text(emoji)
                            .font(.system(size: 13))
                            .frame(width: 26, height: 26)
                            .background(Color(hex: "B2B2B2").opacity(0.3))
                            .clipShape(Circle())
                    } else if model.wantsNearestLocation {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "B2B2B2").opacity(0.3))
                                .frame(width: 26, height: 26)
                            if isHovered {
                                Image(NetworkProtectionAsset.nearestAvailable)
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(NetworkProtectionAsset.nearestAvailable)
                                    .renderingMode(colorScheme == .light ? .original : .template)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                    if #available(macOS 12, *) {
                        if isHovered {
                            Text(model.plainLocation)
                                .applyLocationAttributes()
                                .foregroundColor(.white)
                        } else {
                            Text(model.formattedLocation(colorScheme: colorScheme))
                                .applyLocationAttributes()
                        }
                    } else {
                        Text(model.plainLocation)
                            .applyLocationAttributes()
                            .foregroundColor(isHovered ? .white: Color(.defaultText))
                    }
                }
            }

            dividerRow()
        }
    }

    /// Connection status: server IP address and location
    ///
    private func connectionStatusView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(UserText.networkProtectionStatusViewConnDetails)
                .applySectionHeaderAttributes(colorScheme: colorScheme)
                .padding(EdgeInsets(top: 6, leading: 9, bottom: 6, trailing: 9))

            connectionDetailRow(title: UserText.networkProtectionStatusViewIPAddress,
                                details: model.serverAddress)

            if model.dnsSettings.usesCustomDNS {
                connectionDetailRow(title: UserText.vpnDnsServer,
                                    details: String(describing: model.dnsSettings))
            }

            dataVolumeRow(title: UserText.vpnDataVolume, dataVolume: model.formattedDataVolume)

            dividerRow()
        }
    }

    // MARK: - Rows

    private func dividerRow() -> some View {
        Divider()
            .padding(EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
    }

    private func featureToggleRow() -> some View {
        Toggle(isOn: model.isToggleOn) {
            HStack {
                Text(UserText.networkProtectionStatusViewConnLabel)
                    .applyLabelAttributes(colorScheme: colorScheme)
                    .frame(alignment: .leading)
                    .fixedSize()
                    .disabled(on: !isEnabled)

                Spacer(minLength: 8)

                statusBadge(isConnected: model.isToggleOn.wrappedValue)

                Text(model.connectionStatusDescription)
                    .applyTimerAttributes(colorScheme: colorScheme)
                    .fixedSize()
                    .disabled(on: !isEnabled)

                Spacer()
                    .frame(width: 8)
            }
        }
        .disabled(!isEnabled || model.isToggleDisabled)
        .toggleStyle(.switch)
        .padding(EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9))
    }

    private func connectionDetailRow(title: String, details: String) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .applyLabelAttributes(colorScheme: colorScheme)
                .fixedSize()

            Spacer(minLength: 16)

            Text(details)
                .makeSelectable()
                .applyConnectionStatusDetailAttributes(colorScheme: colorScheme)
                .fixedSize()
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 0, trailing: 9))
    }

    private func dataVolumeRow(title: String, dataVolume: TunnelControllerViewModel.FormattedDataVolume) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .applyLabelAttributes(colorScheme: colorScheme)
                .fixedSize()

            Spacer(minLength: 2)

            Group {
                Image(NetworkProtectionAsset.dataReceived)
                    .renderingMode(colorScheme == .light ? .original : .template)
                    .frame(width: 12, height: 12)
                Text(dataVolume.dataReceived)
                    .applyDataVolumeAttributes(colorScheme: colorScheme)
                Image(NetworkProtectionAsset.dataSent)
                    .renderingMode(colorScheme == .light ? .original : .template)
                    .frame(width: 12, height: 12)
                    .padding(.leading, 4)
                Text(dataVolume.dataSent)
                    .applyDataVolumeAttributes(colorScheme: colorScheme)
            }
            .fixedSize()
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 9))
    }
}
