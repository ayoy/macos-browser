//
//  SpecialPagesUserScriptExtension.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

import Foundation
import BrowserServicesKit

extension SpecialPagesUserScript {
    @MainActor
    func withOnboarding() {
        let onboardingManager = buildOnboardingActionsManager()
        let onboardingScript = OnboardingUserScript(onboardingActionsManager: onboardingManager)
        self.registerSubfeature(delegate: onboardingScript)
    }

    func withDuckPlayerIfAvailable() {
        var youtubePlayerUserScript: YoutubePlayerUserScript?
        if DuckPlayer.shared.isAvailable {
            youtubePlayerUserScript = YoutubePlayerUserScript()
        }
        if let youtubePlayerUserScript {
            self.registerSubfeature(delegate: youtubePlayerUserScript)
        }
    }

    func withErrorPages() {
        let sslErrorPageUserScript = SSLErrorPageUserScript()
        self.registerSubfeature(delegate: sslErrorPageUserScript)
    }

    @MainActor
    func withAllSubfeatures() {
        withOnboarding()
        withErrorPages()
        withDuckPlayerIfAvailable()
    }

    @MainActor
    private func buildOnboardingActionsManager() -> OnboardingActionsManaging {
        return OnboardingActionsManager(
            navigationDelegate: WindowControllersManager.shared,
            dockCustomization: DockCustomizer(),
            defaultBrowserProvider: SystemDefaultBrowserProvider(),
            appearancePreferences: AppearancePreferences.shared,
            startupPreferences: StartupPreferences.shared)
    }
}
