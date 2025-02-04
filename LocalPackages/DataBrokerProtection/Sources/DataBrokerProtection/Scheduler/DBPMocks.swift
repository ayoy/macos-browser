//
//  DBPMocks.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import Combine
import Common

/*
 This mock is a hack for now
 We ideally should refactor the privacy config out of the main app
 Into a local package, so that it can be be used here
 */
public final class PrivacyConfigurationManagingMock: PrivacyConfigurationManaging {

    var data: Data {
        let configString = """
    {
            "readme": "https://github.com/duckduckgo/privacy-configuration",
            "version": 1693838894358,
            "features": {
                "brokerProtection": {
                    "state": "enabled",
                    "exceptions": [],
                    "settings": {}
                }
            },
            "unprotectedTemporary": []
        }
    """
        let data = configString.data(using: .utf8)
        return data!
    }

    public var currentConfig: Data {
        data
    }

    public var updatesPublisher: AnyPublisher<Void, Never> = .init(Just(()))

    public var privacyConfig: BrowserServicesKit.PrivacyConfiguration {
        guard let privacyConfigurationData = try? PrivacyConfigurationData(data: data) else {
            fatalError("Could not retrieve privacy configuration data")
        }
        let privacyConfig = privacyConfiguration(withData: privacyConfigurationData,
                                                 internalUserDecider: internalUserDecider)
        return privacyConfig
    }

    public var internalUserDecider: InternalUserDecider = DefaultInternalUserDecider(store: InternalUserDeciderStoreMock())

    public func reload(etag: String?, data: Data?) -> PrivacyConfigurationManager.ReloadResult {
        .downloaded
    }
}

func privacyConfiguration(withData data: PrivacyConfigurationData,
                          internalUserDecider: InternalUserDecider) -> PrivacyConfiguration {
    let domain = MockDomainsProtectionStore()
    return AppPrivacyConfiguration(data: data,
                                   identifier: UUID().uuidString,
                                   localProtection: domain,
                                   internalUserDecider: internalUserDecider)
}

final class MockDomainsProtectionStore: DomainsProtectionStore {
    var unprotectedDomains = Set<String>()

    func disableProtection(forDomain domain: String) {
        unprotectedDomains.insert(domain)
    }

    func enableProtection(forDomain domain: String) {
        unprotectedDomains.remove(domain)
    }
}

final class InternalUserDeciderStoreMock: InternalUserStoring {
    var isInternalUser: Bool = false
}
