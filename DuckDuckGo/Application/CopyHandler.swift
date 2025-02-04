//
//  CopyHandler.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

final class CopyHandler: NSObject {

    static let copySelector = #selector(Self.copy(_:))

    @IBAction func copy(_ sender: Any?) {
        guard let responder = NSApp.keyWindow?.firstResponder else { return }
        guard let editor = responder as? AddressBarTextEditor else {
            NSApp.sendAction(Self.copySelector, to: responder, from: self)
            return
        }

        let selectedText = editor.selectedText

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)

        if let url = URL(trimmedAddressBarString: selectedText.trimmingWhitespace()) {
            NSPasteboard.general.copy(url, withString: selectedText)
        } else {
            NSPasteboard.general.copy(selectedText)
        }
    }

}
